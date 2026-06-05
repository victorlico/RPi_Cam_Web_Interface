<?php
define('BASE_DIR', dirname(__FILE__));
require_once(BASE_DIR.'/config.php');

define('FISHCAM_CAPTURE_CONF', '/var/www/html/fishcam_capture.conf');
define('FISHCAM_APPLY_CAPTURE_MACRO', '/var/www/html/macros/fishcam_apply_capture_cycle');
define('FISHCAM_DISABLE_CAPTURE_MACRO', '/var/www/html/macros/fishcam_apply_capture_cycle_disable');

$captureMessage = '';
$captureOutput = '';
$captureMessageClass = 'alert-info';

function fishcam_load_capture_config() {

    $config = array();

    if (!file_exists(FISHCAM_CAPTURE_CONF)) {
        return $config;
    }

    $lines = file(FISHCAM_CAPTURE_CONF, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);

    foreach ($lines as $line) {

        $line = trim($line);

        if ($line === '' || substr($line, 0, 1) === '#') {
            continue;
        }

        $parts = explode('=', $line, 2);

        if (count($parts) !== 2) {
            continue;
        }

        $key = trim($parts[0]);
        $value = trim($parts[1]);
        $value = trim($value, "\"'");

        $config[$key] = $value;
    }

    return $config;
}

function fishcam_config_value($config, $key, $default = '') {

    if (isset($config[$key])) {
        return htmlspecialchars($config[$key]);
    }

    return htmlspecialchars($default);
}

function fishcam_config_checked($config, $key, $expected) {

    if (isset($config[$key]) && $config[$key] == $expected) {
        return 'checked';
    }

    return '';
}

function fishcam_interval_minutes_value($config, $defaultSeconds = 300) {

    $seconds = $defaultSeconds;

    if (isset($config['FISHCAM_INTERVAL_SECONDS'])) {
        $seconds = intval($config['FISHCAM_INTERVAL_SECONDS']);
    }

    if ($seconds <= 0) {
        $seconds = $defaultSeconds;
    }

    return htmlspecialchars(strval($seconds / 60));
}

function fishcam_format_capture_config($config) {

    if (empty($config)) {
        return "No automatic capture configuration found.";
    }

    $out = '';

    foreach ($config as $key => $value) {
        $out .= $key . '=' . $value . "\n";
    }

    return $out;
}

function fishcam_macro_message($output) {

    if (strpos($output, 'MODE=power_cycle') !== false) {
        return 'Automatic capture configured. Power saving cycle selected.';
    }

    if (strpos($output, 'MODE=continuous_periodic') !== false) {
        return 'Automatic capture configured. Interval is short, so Raspberry Pi will remain on and record periodically.';
    }

    if (strpos($output, 'MODE=disabled') !== false) {
        return 'Automatic capture cycle disabled.';
    }

    if (strpos($output, 'ERROR') !== false) {
        return 'Error while applying automatic capture configuration.';
    }

    return 'Automatic capture configuration applied.';
}

function fishcam_apply_capture_cycle($recordSeconds, $intervalSeconds, $bootMargin, $finalizeSeconds, $minOffSeconds) {

    if ($recordSeconds < 5) {
        return array(
            'ok' => false,
            'message' => 'Video duration must be at least 5 seconds.',
            'output' => ''
        );
    }

    if ($intervalSeconds <= $recordSeconds) {
        return array(
            'ok' => false,
            'message' => 'Interval must be greater than video duration.',
            'output' => ''
        );
    }

    if ($bootMargin < 10) {
        $bootMargin = 10;
    }

    if ($finalizeSeconds < 5) {
        $finalizeSeconds = 5;
    }

    if ($minOffSeconds < 10) {
        $minOffSeconds = 10;
    }

    if (!file_exists(FISHCAM_APPLY_CAPTURE_MACRO)) {
        return array(
            'ok' => false,
            'message' => 'Macro not found: ' . FISHCAM_APPLY_CAPTURE_MACRO,
            'output' => ''
        );
    }

    $cmd = 'sudo ' . escapeshellcmd(FISHCAM_APPLY_CAPTURE_MACRO) . ' ' .
           escapeshellarg($recordSeconds) . ' ' .
           escapeshellarg($intervalSeconds) . ' ' .
           escapeshellarg($bootMargin) . ' ' .
           escapeshellarg($finalizeSeconds) . ' ' .
           escapeshellarg($minOffSeconds);

    $output = shell_exec($cmd . ' 2>&1');

    return array(
        'ok' => true,
        'message' => fishcam_macro_message($output),
        'output' => $output
    );
}

function fishcam_disable_capture_cycle() {

    if (!file_exists(FISHCAM_DISABLE_CAPTURE_MACRO)) {
        return array(
            'ok' => false,
            'message' => 'Disable macro not found: ' . FISHCAM_DISABLE_CAPTURE_MACRO,
            'output' => ''
        );
    }

    $cmd = 'sudo ' . escapeshellcmd(FISHCAM_DISABLE_CAPTURE_MACRO);
    $output = shell_exec($cmd . ' 2>&1');

    return array(
        'ok' => true,
        'message' => fishcam_macro_message($output),
        'output' => $output
    );
}

function process_capture_cycle_post() {

    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        return null;
    }

    if (!isset($_POST['apply_capture_cycle'])) {
        return null;
    }

    $enabled = isset($_POST['capture_enabled']) ? 1 : 0;

    if ($enabled !== 1) {
        return fishcam_disable_capture_cycle();
    }

    $recordSeconds = intval($_POST['record_seconds']);
    $intervalMinutes = intval($_POST['interval_minutes']);
    $intervalSeconds = $intervalMinutes * 60;

    $bootMargin = intval($_POST['boot_margin_seconds']);
    $finalizeSeconds = intval($_POST['finalize_seconds']);
    $minOffSeconds = intval($_POST['min_off_seconds']);

    return fishcam_apply_capture_cycle(
        $recordSeconds,
        $intervalSeconds,
        $bootMargin,
        $finalizeSeconds,
        $minOffSeconds
    );
}

$postResult = process_capture_cycle_post();

if ($postResult !== null) {
    $captureMessage = $postResult['message'];
    $captureOutput = $postResult['output'];
    $captureMessageClass = $postResult['ok'] ? 'alert-info' : 'alert-danger';
}

function mainHTML() {
    global $debugString;
    global $captureMessage;
    global $captureOutput;
    global $captureMessageClass;

    $captureConfig = fishcam_load_capture_config();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=550, initial-scale=1">
    <title><?php echo CAM_STRING; ?> WittyPi Control</title>
    <link rel="stylesheet" href="css/style_minified.css" />
    <link rel="stylesheet" href="<?php echo getStyle(); ?>" />
    <script src="js/style_minified.js"></script>
    <script src="js/script.js"></script>

    <script>
        function fishcam_format_seconds(totalSeconds) {
            totalSeconds = parseInt(totalSeconds || '0', 10);

            var minutes = Math.floor(totalSeconds / 60);
            var seconds = totalSeconds % 60;

            if (minutes > 0 && seconds > 0) {
                return minutes + 'min ' + seconds + 's';
            }

            if (minutes > 0) {
                return minutes + 'min';
            }

            return seconds + 's';
        }

        function update_capture_cycle_preview() {
            var recordInput = document.getElementById('record_seconds');
            var intervalInput = document.getElementById('interval_minutes');
            var bootInput = document.getElementById('boot_margin_seconds');
            var finalizeInput = document.getElementById('finalize_seconds');
            var minOffInput = document.getElementById('min_off_seconds');
            var preview = document.getElementById('capture_cycle_preview');

            if (!recordInput || !intervalInput || !bootInput || !finalizeInput || !minOffInput || !preview) {
                return;
            }

            var recordSeconds = parseInt(recordInput.value || '0', 10);
            var intervalSeconds = parseInt(intervalInput.value || '0', 10) * 60;
            var bootMargin = parseInt(bootInput.value || '0', 10);
            var finalizeSeconds = parseInt(finalizeInput.value || '0', 10);
            var minOffSeconds = parseInt(minOffInput.value || '0', 10);

            if (recordSeconds <= 0 || intervalSeconds <= 0) {
                preview.innerHTML = 'Fill the fields to preview the selected mode.';
                return;
            }

            if (intervalSeconds <= recordSeconds) {
                preview.innerHTML = '<b>Invalid configuration:</b> interval must be greater than video duration.';
                return;
            }

            var requiredOn = bootMargin + recordSeconds + finalizeSeconds;
            var offSeconds = intervalSeconds - requiredOn;

            if (offSeconds >= minOffSeconds) {
                preview.innerHTML =
                    '<b>Estimated mode:</b> Power saving cycle<br>' +
                    'Raspberry Pi ON time: approximately <b>' + fishcam_format_seconds(requiredOn) + '</b><br>' +
                    'Raspberry Pi OFF time: approximately <b>' + fishcam_format_seconds(offSeconds) + '</b><br>' +
                    'Video duration: approximately <b>' + fishcam_format_seconds(recordSeconds) + '</b>';
            } else {
                preview.innerHTML =
                    '<b>Estimated mode:</b> Periodic recording while powered on<br>' +
                    'The selected interval is too short for safe power cycling.<br>' +
                    'The Raspberry Pi will remain on and record <b>' +
                    fishcam_format_seconds(recordSeconds) +
                    '</b> videos every <b>' +
                    fishcam_format_seconds(intervalSeconds) +
                    '</b>.';
            }
        }

        function init_fishcam_capture_cycle_form() {
            var ids = [
                'record_seconds',
                'interval_minutes',
                'boot_margin_seconds',
                'finalize_seconds',
                'min_off_seconds'
            ];

            for (var i = 0; i < ids.length; i++) {
                var element = document.getElementById(ids[i]);

                if (element) {
                    element.addEventListener('input', update_capture_cycle_preview);
                    element.addEventListener('change', update_capture_cycle_preview);
                }
            }

            update_capture_cycle_preview();
        }

        function init_power_schedule_with_capture_cycle() {
            if (typeof init_power_schedule_page === 'function') {
                init_power_schedule_page();
            }

            init_fishcam_capture_cycle_form();
        }
    </script>
</head>
<body onload="init_power_schedule_with_capture_cycle()">
    <div class="navbar navbar-inverse navbar-fixed-top" role="navigation">
        <div class="container">
            <div class="navbar-header">
                <a class="navbar-brand" href="<?php echo ROOT_PHP; ?>">
                    <span class="glyphicon glyphicon-chevron-left"></span>Back - <?php echo CAM_STRING; ?>
                </a>
            </div>
        </div>
    </div>

    <div class="container-fluid text-center" style="margin-top: 60px;">
        <h2>⚙️ WittyPi Control</h2>
        <?php if ($debugString) echo $debugString . "<br>"; ?>

        <div style="margin-bottom:10px;">
            <button class="btn btn-primary" type="button" onclick="wittypi_pause_loop()">1. Pause Loop</button>
            <button class="btn btn-warning" type="button" onclick="wittypi_reset()">4. Reset System</button>
        </div>

        <hr>

        <h3>🎥 Automatic Capture Cycle</h3>

        <div style="max-width:720px;margin:0 auto;text-align:left;">

            <?php if (!empty($captureMessage)): ?>
                <div class="alert <?php echo $captureMessageClass; ?>">
                    <?php echo htmlspecialchars($captureMessage); ?>
                </div>
            <?php endif; ?>

            <?php if (!empty($captureOutput)): ?>
                <pre style="text-align:left;"><?php echo htmlspecialchars($captureOutput); ?></pre>
            <?php endif; ?>

            <form method="post" id="fishcam_capture_cycle_form">

                <div class="form-group">
                    <label>
                        <input type="checkbox" name="capture_enabled" value="1"
                            <?php echo fishcam_config_checked($captureConfig, 'FISHCAM_ENABLED', '1'); ?>>
                        Enable automatic capture cycle
                    </label>
                </div>

                <div class="form-group">
                    <label for="record_seconds"><b>Video duration</b></label>
                    <div>
                        <input
                            type="number"
                            class="form-control"
                            id="record_seconds"
                            name="record_seconds"
                            value="<?php echo fishcam_config_value($captureConfig, 'FISHCAM_RECORD_SECONDS', '60'); ?>"
                            min="5"
                            step="1">
                        <small>seconds</small>
                    </div>
                </div>

                <div class="form-group">
                    <label for="interval_minutes"><b>Interval between recordings</b></label>
                    <div>
                        <input
                            type="number"
                            class="form-control"
                            id="interval_minutes"
                            name="interval_minutes"
                            value="<?php echo fishcam_interval_minutes_value($captureConfig, 300); ?>"
                            min="1"
                            step="1">
                        <small>minutes, measured from the start of one video to the start of the next</small>
                    </div>
                </div>

                <details style="margin-top:10px;">
                    <summary><b>Advanced settings</b></summary>

                    <div class="form-group" style="margin-top:10px;">
                        <label for="boot_margin_seconds">Boot/ready margin</label>
                        <input
                            type="number"
                            class="form-control"
                            id="boot_margin_seconds"
                            name="boot_margin_seconds"
                            value="<?php echo fishcam_config_value($captureConfig, 'FISHCAM_BOOT_MARGIN_SECONDS', '60'); ?>"
                            min="10"
                            step="1">
                        <small>seconds reserved for Raspberry Pi boot, storage mount and RPi-Cam readiness</small>
                    </div>

                    <div class="form-group">
                        <label for="finalize_seconds">Finalize/boxing margin</label>
                        <input
                            type="number"
                            class="form-control"
                            id="finalize_seconds"
                            name="finalize_seconds"
                            value="<?php echo fishcam_config_value($captureConfig, 'FISHCAM_FINALIZE_SECONDS', '45'); ?>"
                            min="5"
                            step="1">
                        <small>seconds reserved after stopping video before shutdown</small>
                    </div>

                    <div class="form-group">
                        <label for="min_off_seconds">Minimum safe off time</label>
                        <input
                            type="number"
                            class="form-control"
                            id="min_off_seconds"
                            name="min_off_seconds"
                            value="<?php echo fishcam_config_value($captureConfig, 'FISHCAM_MIN_OFF_SECONDS', '60'); ?>"
                            min="10"
                            step="1">
                        <small>if calculated off time is smaller than this, Raspberry Pi will stay powered on</small>
                    </div>
                </details>

                <div id="capture_cycle_preview" class="alert alert-info" style="margin-top:15px;">
                    Fill the fields to preview the selected mode.
                </div>

                <button type="submit" name="apply_capture_cycle" value="1" class="btn btn-success">
                    💾 Apply Automatic Capture Cycle
                </button>

            </form>

            <hr>

            <h4>Current automatic capture configuration</h4>
            <pre style="text-align:left;"><?php echo htmlspecialchars(fishcam_format_capture_config($captureConfig)); ?></pre>
        </div>

        <hr>

        <h3>📄 2. Edit Schedule</h3>

        <div style="max-width:720px;margin:0 auto;">
            <div class="form-group">
                <label for="preset"><b>Presets:</b></label>
                <select id="preset" onchange="apply_preset_from_select(this.value)" class="form-control">
                    <option value="__custom__">✏️ Custom</option>
                    <!-- opções serão preenchidas via AJAX -->
                </select>
            </div>

            <textarea id="schedule_text" rows="12" class="form-control" placeholder="Loading schedule..."></textarea>

            <div style="margin-top:10px;">
                <button class="btn btn-success" onclick="save_schedule()">💾 3. Save Schedule</button>
                <button class="btn btn-info" onclick="load_schedule()">↻ Reload Schedule</button>
            </div>

            <p id="schedule_hint" style="margin-top:10px;color:#888;"></p>
        </div>
    </div>
</body>
</html>
<?php
}

mainHTML();