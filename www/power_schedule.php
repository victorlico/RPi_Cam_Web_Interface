<?php
define('BASE_DIR', dirname(__FILE__));
require_once(BASE_DIR.'/config.php');

function mainHTML() {
    global $debugString;
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
</head>
<body onload="wittypi_init();">
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
        
        <div style="margin-bottom:16px;">
            <button class="btn btn-primary" type="button" onclick="wittypi_pause_loop()">Pause Loop</button>
            <button class="btn btn-warning" type="button" onclick="wittypi_reset()">Reset System</button>
        </div>

        <hr>

        <h3>📄 Edit Schedule</h3>
        <label for="preset">Presets:</label>
        <select id="preset" onchange="on_preset_change(this.value)">
            <option value="custom">✏️ Custom</option>
            <!-- opções carregadas via JS de /var/www/html/macros/wittypi_presets -->
        </select>
        <br><br>

        <textarea id="schedule_text" rows="12" cols="60" placeholder="Loading schedule..."></textarea>
        <br><br>
        <button class="btn btn-success" onclick="save_schedule()">💾 Save Schedule</button>
        <button class="btn btn-info" onclick="load_schedule()">↻ Reload Schedule</button>
    </div>
</body>
</html>
<?php
}
mainHTML();
