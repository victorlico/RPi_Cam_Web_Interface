<?php
define('BASE_DIR', dirname(__FILE__));
require_once(BASE_DIR.'/config.php');

$file_path  = "/home/fish_cam/wittypi/schedule.wpi";
$preset_dir = "/var/www/html/macros/wittypi_presets";

function sys_cmd($cmd) {
    global $file_path, $preset_dir;
    $output = "";

    if (strncmp($cmd, "reboot", strlen("reboot")) == 0) {
        $output = shell_exec('sudo shutdown -r now 2>&1');
    } 
    else if (strncmp($cmd, "shutdown", strlen("shutdown")) == 0) {
        $output = shell_exec('sudo shutdown -h now 2>&1');
    } 
    else if (strncmp($cmd, "settime", strlen("settime")) == 0) {
        if (isset($_GET['timestr'])) {
            $timestr = $_GET['timestr'];
            if ($timestr !== "" && strpos($timestr, "-") === false && date_create($timestr) !== FALSE) {
                $output = shell_exec("sudo date -s \"$timestr\" 2>&1");
            } else {
                $output = "❌ Invalid time format.";
            }
        } else {
            $output = "❌ Missing 'timestr'.";
        }
    } 
    else if (strncmp($cmd, "pause_loop", strlen("pause_loop")) == 0) {
        $output = shell_exec('sudo /var/www/html/macros/wittypi_pause_loop 2>&1');
        if ($output === null) $output = "❌ Failed to run wittypi_pause_loop.";
    } 
    else if (strncmp($cmd, "reset_wittypi", strlen("reset_wittypi")) == 0) {
        $output = shell_exec('sudo /var/www/html/macros/wittypi_reset 2>&1');
        if ($output === null) $output = "❌ Failed to run wittypi_reset.";
    } 
    else if (strncmp($cmd, "get_schedule", strlen("get_schedule")) == 0) {
        if (file_exists($file_path)) {
            $content = file_get_contents($file_path);
            $output = ($content !== false) ? $content : "❌ Error reading schedule file";
        } else {
            // marcador para o JS saber que é “primeiro uso” e ainda não existe arquivo
            $output = "__NO_SCHEDULE__";
        }
    }
    else if (strncmp($cmd, "save_schedule", strlen("save_schedule")) == 0) {
        if (isset($_POST['data'])) {
            $new_content = $_POST['data'];

            $descriptorspec = [
                0 => ["pipe", "r"],
                1 => ["pipe", "w"],
                2 => ["pipe", "w"],
            ];
            $process = proc_open('sudo /var/www/html/macros/wittypi_write_schedule', $descriptorspec, $pipes);

            if (is_resource($process)) {
                fwrite($pipes[0], $new_content);
                fclose($pipes[0]);

                $stdout = stream_get_contents($pipes[1]); fclose($pipes[1]);
                $stderr = stream_get_contents($pipes[2]); fclose($pipes[2]);

                $status = proc_close($process);

                if ($status === 0) {
                    $output = "✅ Schedule saved successfully!";
                    if (trim($stdout) !== "") $output .= " (" . trim($stdout) . ")";
                } else {
                    $output = "❌ Failed to save schedule! " . trim($stderr);
                }
            } else {
                $output = "❌ Failed to start writer process.";
            }
        } else {
            $output = "❌ No schedule data received!";
        }
    }
    else if (strncmp($cmd, "list_presets", strlen("list_presets")) == 0) {
        $list = [];
        if (is_dir($preset_dir)) {
            foreach (scandir($preset_dir) as $f) {
                if (preg_match('/^[A-Za-z0-9._-]+\.wpi$/', $f)) {
                    $label = preg_replace('/\.wpi$/', '', $f);
                    $label = str_replace(['_', '-'], ' ', $label);
                    $list[] = ['file' => $f, 'label' => $label];
                }
            }
        }
        header('Content-Type: application/json; charset=utf-8');
        return json_encode($list);
    }
    else if (strncmp($cmd, "get_preset", strlen("get_preset")) == 0) {
        if (!isset($_GET['file'])) {
            return "❌ Missing preset file parameter.";
        }
        $fname = $_GET['file'];
        if (!preg_match('/^[A-Za-z0-9._-]+\.wpi$/', $fname)) {
            return "❌ Invalid preset filename.";
        }
        $path = $preset_dir . '/' . $fname;
        if (!is_file($path)) {
            return "❌ Preset not found.";
        }
        $content = file_get_contents($path);
        if ($content === false) {
            return "❌ Error reading preset.";
        }
        return $content;
    }
    else {
        $output = "❌ Unknown command.";
    }

    return trim($output);
}

if (isset($_GET['cmd'])) {
    $cmd = $_GET['cmd'];
    echo sys_cmd($cmd);
}
