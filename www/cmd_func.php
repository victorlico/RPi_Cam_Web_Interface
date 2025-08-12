<?php
define('BASE_DIR', dirname(__FILE__));
require_once(BASE_DIR.'/config.php');

function sys_cmd($cmd) {
    $output = "";
    $macros_dir = BASE_DIR . '/macros';
    $presets_dir = $macros_dir . '/wittypi_presets';

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
            $output = "❌ No time passed.";
        }
    }
    else if (strncmp($cmd, "pause_loop", strlen("pause_loop")) == 0) {
        $output = shell_exec('sudo ' . $macros_dir . '/wittypi_pause_loop 2>&1');
    }
    else if (strncmp($cmd, "reset_wittypi", strlen("reset_wittypi")) == 0) {
        $output = shell_exec('sudo ' . $macros_dir . '/wittypi_reset 2>&1');
    }
    else if (strncmp($cmd, "get_schedule", strlen("get_schedule")) == 0) {
        // Lê via script para não depender do usuário do /home
        $output = shell_exec('sudo ' . $macros_dir . '/wittypi_read_schedule 2>&1');
        if ($output === null) $output = "❌ Failed to read schedule (no output).";
    }
    else if (strncmp($cmd, "save_schedule", strlen("save_schedule")) == 0) {
        if (!isset($_POST['data'])) {
            $output = "❌ No schedule data received!";
        } else {
            // Envia o conteúdo via STDIN para o writer (mv atômico)
            $descriptorspec = [
                0 => ["pipe", "r"],
                1 => ["pipe", "w"],
                2 => ["pipe", "w"],
            ];
            $process = proc_open('sudo ' . $macros_dir . '/wittypi_write_schedule', $descriptorspec, $pipes);
            if (is_resource($process)) {
                fwrite($pipes[0], $_POST['data']);
                fclose($pipes[0]);

                $stdout = stream_get_contents($pipes[1]); fclose($pipes[1]);
                $stderr = stream_get_contents($pipes[2]); fclose($pipes[2]);
                $code = proc_close($process);

                if ($code === 0) {
                    $output = "✅ Schedule saved successfully! " . trim($stdout);
                } else {
                    $output = "❌ Failed to save schedule! " . trim($stderr);
                }
            } else {
                $output = "❌ Could not launch writer.";
            }
        }
    }
    else if (strncmp($cmd, "list_presets", strlen("list_presets")) == 0) {
        $result = [];
        if (is_dir($presets_dir)) {
            $files = glob($presets_dir . '/*.wpi');
            if ($files !== false) {
                foreach ($files as $f) {
                    $name = basename($f, '.wpi'); // nome sem extensão
                    $content = @file_get_contents($f);
                    if ($content === false) $content = "";
                    $result[] = ["name" => $name, "content" => $content];
                }
            }
        }
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($result);
        return ""; // já respondemos
    }
    else {
        $output = "❌ Unknown command.";
    }

    return trim($output);
}

if (isset($_GET['cmd'])) {
    $cmd = $_GET['cmd'];
    $resp = sys_cmd($cmd);
    if ($resp !== "") echo $resp;
}
