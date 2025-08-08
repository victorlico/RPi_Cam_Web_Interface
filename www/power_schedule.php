<?php
   define('BASE_DIR', dirname(__FILE__));
   require_once(BASE_DIR.'/config.php');

   function mainHTML() {
      global $debugString;
      echo '<!DOCTYPE html>';
      echo '<html>';
         echo '<head>';
            echo '<meta name="viewport" content="width=550, initial-scale=1">';
            echo '<title>' . CAM_STRING . ' Custom Actions</title>';
            echo '<link rel="stylesheet" href="css/style_minified.css" />';
            echo '<link rel="stylesheet" href="' . getStyle() . '" />';
            echo '<script src="js/style_minified.js"></script>';
            echo '<script src="js/script.js"></script>';
         echo '</head>';
         echo '<body>';
            echo '<div class="navbar navbar-inverse navbar-fixed-top" role="navigation">';
               echo '<div class="container">';
                  echo '<div class="navbar-header">';
                     echo '<a class="navbar-brand" href="' . ROOT_PHP . '">';
                     echo '<span class="glyphicon glyphicon-chevron-left"></span>Back - ' . CAM_STRING . '</a>';
                  echo '</div>';
               echo '</div>';
            echo '</div>';
          
            echo '<div class="container-fluid text-center">';
               echo '<form action="power_schedule.php" method="POST">';
                  if ($debugString) echo $debugString . "<br>";
                  echo '<div class="container-fluid text-center">';
                     echo '<button class="btn btn-primary" type="button" onclick="wittypi_pause_loop()">Pause Loop</button>';
                     echo '<button class="btn btn-warning" type="button" onclick="wittypi_reset()">Reset System</button> ';
                     echo '<button class="btn btn-primary" type="submit" name="action" value="update_schedule">Update Power Schedule</button><br><br>';
                     echo '<textarea id="custom_input" name="custom_input" rows="10" cols="50" style="resize: vertical; overflow-y: auto;" placeholder="Enter schedule script for ~/wittypi/schedule.wpi"></textarea>';
                  echo '</div>';
               echo '</form>';
            echo '</div>';
         echo '</body>';
      echo '</html>';
   }

   if (isset($_POST['action']) && $_POST['action'] == 'update_schedule') {
      $custom_input = $_POST['custom_input'];
      if ($custom_input !== '') {
         // Substitui o conteúdo do arquivo ~/wittypi/schedule.wpi
         $file_path = $_SERVER['HOME'] . '/wittypi/schedule.wpi';
         if (file_put_contents($file_path, $custom_input) !== false) {
            writeLog("Schedule updated successfully: " . $custom_input);
         } else {
            writeLog("Error writing to schedule.wpi");
         }
      } else {
         writeLog("No schedule input provided");
      }
   }

   mainHTML();
?>