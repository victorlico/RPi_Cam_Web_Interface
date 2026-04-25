//
// Interface
//
var elem = document.documentElement;
function openFullscreen() {
  if (elem.requestFullscreen) {
    elem.requestFullscreen();
  } else if (elem.webkitRequestFullscreen) { /* Safari */
    elem.webkitRequestFullscreen();
  } else if (elem.msRequestFullscreen) { /* IE11 */
    elem.msRequestFullscreen();
  }
}

function closeFullscreen() {
  if (document.exitFullscreen) {
    document.exitFullscreen();
  } else if (document.webkitExitFullscreen) { /* Safari */
    document.webkitExitFullscreen();
  } else if (document.msExitFullscreen) { /* IE11 */
    document.msExitFullscreen();
  }
}

function toggle_fullscreen(e) {
  var background = document.getElementById("background");
  if(!background) {
    background = document.createElement("div");
    background.id = "background";
    document.body.appendChild(background);
  }
  if(e.className == "fullscreen") {
    e.className = "";
    background.style.display = "none";
    closeFullscreen();
  }
  else {
    e.className = "fullscreen";
    background.style.display = "block";
    openFullscreen();
  }
}

function set_display(value) {
   var d = new Date();
   var val;
   d.setTime(d.getTime() + (365*24*60*60*1000));
   var expires = "expires="+d.toUTCString();
   if (value == "SimpleOff") {
	   val = "Off";
   } else if (value == "SimpleOn") {
	   val = "Full";
   } else {
	   val = value
   }
   document.cookie="display_mode=" + val + "; " + expires;
   document.location.reload(true);
}

function set_stream_mode(value) {
   var d = new Date();
   d.setTime(d.getTime() + (365*24*60*60*1000));
   var expires = "expires="+d.toUTCString();
   if (value == "DefaultStream") {
      document.getElementById("toggle_stream").value = "MJPEG-Stream";
   } else {
      document.getElementById("toggle_stream").value = "Default-Stream";
   }
   document.cookie="stream_mode=" + value + "; " + expires;
   document.location.reload(true);
}

function schedule_rows() {
   var sun, day, fixed, mode;
   mode = parseInt(document.getElementById("DayMode").value);
   switch(mode) {
      case 0: sun = 'table-row'; day = 'none'; fixed = 'none'; break;
      case 1: sun = 'none'; day = 'table-row'; fixed = 'none'; break;
      case 2: sun = 'none'; day = 'none'; fixed = 'table-row'; break;
      default: sun = 'table-row'; day = 'table-row'; fixed = 'table-row'; break;
   }
   var rows;
   rows = document.getElementsByClassName('sun');
   for(i=0; i<rows.length; i++) rows[i].style.display = sun;
   rows = document.getElementsByClassName('day');
   for(i=0; i<rows.length; i++) rows[i].style.display = day;
   rows = document.getElementsByClassName('fixed');
   for(i=0; i<rows.length; i++) rows[i].style.display = fixed;
}

function set_preset(value) {
  var values = value.split(" ");
  document.getElementById("video_width").value = values[0];
  document.getElementById("video_height").value = values[1];
  document.getElementById("video_fps").value = values[2];
  document.getElementById("MP4Box_fps").value = values[3];
  document.getElementById("image_width").value = values[4];
  document.getElementById("image_height").value = values[5];
  document.getElementById("fps_divider").value = values[6];
  set_res();
}

function set_res() {
  send_cmd("px " + document.getElementById("video_width").value + " " + document.getElementById("video_height").value + " " + document.getElementById("video_fps").value + " " + document.getElementById("MP4Box_fps").value + " " + document.getElementById("image_width").value + " " + document.getElementById("image_height").value + " " + document.getElementById("fps_divider").value);
  update_preview_delay();
  updatePreview(true);
}

function set_ce() {
  send_cmd("ce " + document.getElementById("ce_en").value + " " + document.getElementById("ce_u").value + " " + document.getElementById("ce_v").value);
}

function set_preview() {
  send_cmd("pv " + document.getElementById("quality").value + " " + document.getElementById("width").value + " " + document.getElementById("divider").value);
  update_preview_delay();
}

function set_encoding() {
  send_cmd("qp " + document.getElementById("minimise_frag").value + " " + document.getElementById("initial_quant").value + " " + document.getElementById("encode_qp").value);
}

function set_roi() {
  send_cmd("ri " + document.getElementById("roi_x").value + " " + document.getElementById("roi_y").value + " " + document.getElementById("roi_w").value + " " + document.getElementById("roi_h").value);
}

function set_at() {
  send_cmd("at " + document.getElementById("at_en").value + " " + document.getElementById("at_y").value + " " + document.getElementById("at_u").value + " " + document.getElementById("at_v").value);
}

function set_ac() {
  send_cmd("ac " + document.getElementById("ac_en").value + " " + document.getElementById("ac_y").value + " " + document.getElementById("ac_u").value + " " + document.getElementById("ac_v").value);
}

function set_ag() {
  send_cmd("ag " + document.getElementById("ag_r").value + " " + document.getElementById("ag_b").value);
}

function send_macroUpdate(i, macro) {
  var macrovalue = document.getElementById(macro).value;
  if(!document.getElementById(macro + "_chk").checked) {
	  macrovalue = "-" + macrovalue;
  }
  send_cmd("um " + i + " " + macrovalue);
}

function hashHandler() {
  switch(window.location.hash){
    case '#full':
    case '#fullscreen':
      if (mjpeg_img !== null && document.getElementsByClassName("fullscreen").length == 0) {
        toggle_fullscreen(mjpeg_img);
      }
      break;
    case '#normal':
    case '#normalscreen':
      if (mjpeg_img !== null && document.getElementsByClassName("fullscreen").length != 0) {
        toggle_fullscreen(mjpeg_img);
      }
      break;
  }
}

//
// System shutdown, reboot, settime
//
function sys_shutdown() {
  ajax_status.open("GET", "cmd_func.php?cmd=shutdown", true);
  ajax_status.send();
}

function sys_reboot() {
  ajax_status.open("GET", "cmd_func.php?cmd=reboot", true);
  ajax_status.send();
}

function sys_settime() {
  var strDate = document.getElementById("timestr").value;
  if(strDate.indexOf("-") < 0) {
	  ajax_status.open("GET", "cmd_func.php?cmd=settime&timestr=" + document.getElementById("timestr").value, true);
	  ajax_status.send();
  }
}

function wittypi_pause_loop() {
  ajax_status.open("GET", "cmd_func.php?cmd=pause_loop", true);
  ajax_status.onreadystatechange = function () {
    if (ajax_status.readyState === 4 && ajax_status.status === 200) {
      alert("Pause Loop:\n" + ajax_status.responseText);
    }
  };
  ajax_status.send();
}

function wittypi_reset() {
  ajax_status.open("GET", "cmd_func.php?cmd=reset_wittypi", true);
  ajax_status.onreadystatechange = function () {
    if (ajax_status.readyState === 4 && ajax_status.status === 200) {
      alert("Reset WittyPi:\n" + ajax_status.responseText);
    }
  };
  ajax_status.send();
}

// TODO - add funcao para sincronizar horario com rede e salvar no rtc se for ajuste manual

// ---------- WittyPi schedule (presets + editor) ----------

var ajax_status;
if (window.XMLHttpRequest) {
  ajax_status = new XMLHttpRequest();
} else {
  ajax_status = new ActiveXObject("Microsoft.XMLHTTP");
}

// Carrega presets do servidor (lista arquivos .wpi em macros/wittypi_presets)
function load_presets() {
  var sel = document.getElementById("preset");
  // limpa tudo e recria "Custom"
  sel.innerHTML = '<option value="__custom__">✏️ Custom</option>';

  var xhr = new XMLHttpRequest();
  xhr.open("GET", "cmd_func.php?cmd=list_presets", true);
  xhr.onreadystatechange = function() {
    if (xhr.readyState === 4 && xhr.status === 200) {
      try {
        var list = JSON.parse(xhr.responseText);
        list.forEach(function(item) {
          var opt = document.createElement("option");
          opt.value = "__preset__:" + item.name; // value só carrega o id
          opt.textContent = item.name;
          opt.dataset.content = item.content;    // salva conteúdo no option
          sel.appendChild(opt);
        });
      } catch(e) {
        console.warn("Could not parse presets JSON:", e);
      }
    }
  };
  xhr.send();
}

// Aplica preset selecionado ao textarea
function apply_preset_from_select(val) {
  var textarea = document.getElementById("schedule_text");
  var sel = document.getElementById("preset");

  if (val === "__custom__") {
    // Não altera o texto; usuário é livre para editar
    return;
  }

  // procura option e pega o dataset.content
  var opt = sel.options[sel.selectedIndex];
  var content = opt && opt.dataset ? (opt.dataset.content || "") : "";
  textarea.value = content;
}

// Se o usuário editar o textarea, vira Custom
function on_schedule_input_changed() {
  var sel = document.getElementById("preset");
  if (sel.value !== "__custom__") {
    sel.value = "__custom__";
  }
}

// Carrega o conteúdo atual do schedule.wpi
function load_schedule() {
  var xhr = new XMLHttpRequest();
  xhr.open("GET", "cmd_func.php?cmd=get_schedule", true);
  xhr.onreadystatechange = function () {
    if (xhr.readyState === 4 && xhr.status === 200) {
      var response = xhr.responseText || "";
      var textarea = document.getElementById("schedule_text");
      textarea.value = response;

      var hint = document.getElementById("schedule_hint");
      if (/not found/i.test(response)) {
        hint.textContent = "⚠️ schedule.wpi not found. Choose a preset or write your own in Custom, then click Save Schedule.";
      } else {
        hint.textContent = "";
      }
    }
  };
  xhr.send();
}

// Salva alterações
function save_schedule() {
  var text = document.getElementById("schedule_text").value;

  var xhr = new XMLHttpRequest();
  xhr.open("POST", "cmd_func.php?cmd=save_schedule", true);
  xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  xhr.onreadystatechange = function () {
    if (xhr.readyState === 4 && xhr.status === 200) {
      alert("Save Schedule:\n" + xhr.responseText + "\n\n➡️ Now click 'Reset System' to apply the new schedule.");
      load_schedule();
    }
  };
  xhr.send("data=" + encodeURIComponent(text));
}

// Alerta específico para esta página
function init_power_schedule_page() {
  // alerta para pausar loop (só nesta página)
  if (window.location.pathname.match(/power_schedule\.php$/)) {
    setTimeout(function () {
      alert("Heads up!\n\nTo avoid auto-shutdown while editing, click 'Pause Loop' first.\nConfig Schedule.\nSave Schedule.\nReset System to apply.");
    }, 300);
  }
  // carrega presets e conteúdo do schedule
  load_presets();
  load_schedule();

  // liga o listener de edição para virar Custom
  var textarea = document.getElementById("schedule_text");
  if (textarea) {
    textarea.addEventListener("input", on_schedule_input_changed);
  }
}

// ---------- MJPEG etc (originais da interface) ----------

var mjpeg_img;
var halted = 0;
var previous_halted = 99;
var mjpeg_mode = 0;
var preview_delay = 0;
var btn_class_p = "btn btn-primary";
var btn_class_a = "btn btn-warning";

function reload_img () {
  if(!halted) mjpeg_img.src = "cam_pic.php?time=" + new Date().getTime() + "&pDelay=" + preview_delay;
  else setTimeout(reload_img, 500);
}

function error_img () {
  setTimeout(function(){ mjpeg_img.src = 'cam_pic.php?time=' + new Date().getTime(); }, 100);
}

function updatePreview(cycle) {
   if (mjpegmode) {
      if (cycle !== undefined && cycle == true) {
         mjpeg_img.src = "/updating.jpg";
         setTimeout(function(){ mjpeg_img.src = "cam_pic_new.php?time=" + new Date().getTime()  + "&pDelay=" + preview_delay; }, 1000);
         return;
      }
      if (previous_halted != halted) {
         if(!halted) {
            mjpeg_img.src = "cam_pic_new.php?time=" + new Date().getTime() + "&pDelay=" + preview_delay;			
         } else {
            mjpeg_img.src = "/unavailable.jpg";
         }
      }
	    previous_halted = halted;
   }
}

var ajax_cmd;
if(window.XMLHttpRequest) {
  ajax_cmd = new XMLHttpRequest();
} else {
  ajax_cmd = new ActiveXObject("Microsoft.XMLHTTP");
}

function encodeCmd(s) {
   return s.replace(/&/g,"%26").replace(/#/g,"%23").replace(/\+/g,"%2B");
}

function send_cmd (cmd) {
  ajax_cmd.open("GET","cmd_pipe.php?cmd=" + encodeCmd(cmd),true);
  ajax_cmd.send();
}

function update_preview_delay() {
   var video_fps = parseInt(document.getElementById("video_fps").value);
   var divider = parseInt(document.getElementById("divider").value);
   preview_delay = Math.floor(divider / Math.max(video_fps,1) * 1000000);
}

function init(mjpeg, video_fps, divider) {
  mjpeg_img = document.getElementById("mjpeg_dest");
  hashHandler();
  window.onhashchange = hashHandler;
  preview_delay = Math.floor(divider / Math.max(video_fps,1) * 1000000);
  if (mjpeg) {
    mjpegmode = 1;
  } else {
     mjpegmode = 0;
     mjpeg_img.onload = reload_img;
     mjpeg_img.onerror = error_img;
     reload_img();
  }
  reload_ajax("");
}

function setButtonState(btn_id, disabled, value, cmd=null) {
  btn = document.getElementById(btn_id);
  btn.disabled = disabled;
  btn.value = value;
  if (cmd !== null) btn.onclick = function() {send_cmd(cmd);};
}

function reload_ajax (last) {
  ajax_status.open("GET","status_mjpeg.php?last=" + last,true);
  ajax_status.send();
}

ajax_status.onreadystatechange = function() {
  if(ajax_status.readyState == 4 && ajax_status.status == 200) {

    if(ajax_status.responseText == "ready") {
      setButtonState("video_button", false, "record video start", "ca 1");
      setButtonState("image_button", false, "record image", "im");
      setButtonState("timelapse_button", false, "timelapse start", "tl 1");
      setButtonState("md_button", false, "motion detection start", "md 1");
      setButtonState("halt_button", false, "stop camera", "ru 0");
      document.getElementById("preview_select").disabled = false;
      document.getElementById("video_button").className = btn_class_p;
      document.getElementById("timelapse_button").className = btn_class_p;
      document.getElementById("md_button").className = btn_class_p;
      document.getElementById("image_button").className = btn_class_p;
      halted = 0;
    }
    else if(ajax_status.responseText == "md_ready") {
      setButtonState("video_button", true, "record video start");
      setButtonState("image_button", false, "record image", "im");
      setButtonState("timelapse_button", false, "timelapse start", "tl 1");
      setButtonState("md_button", false, "motion detection stop", "md 0");
      setButtonState("halt_button", true, "stop camera");
      document.getElementById("preview_select").disabled = false;
      document.getElementById("video_button").className = btn_class_p;
      document.getElementById("timelapse_button").className = btn_class_p;
      document.getElementById("md_button").className = btn_class_a;
      document.getElementById("image_button").className = btn_class_p;
      halted = 0;
    }
    else if(ajax_status.responseText == "timelapse") {
      setButtonState("video_button", false, "record video start", "ca 1");
      setButtonState("image_button", true, "record image");
      setButtonState("timelapse_button", false, "timelapse stop", "tl 0");
      setButtonState("md_button", true, "motion detection start");
      setButtonState("halt_button", true, "stop camera");
      document.getElementById("preview_select").disabled = false;
      document.getElementById("video_button").className = btn_class_p;
      document.getElementById("timelapse_button").className = btn_class_a;
      document.getElementById("md_button").className = btn_class_p;
      document.getElementById("image_button").className = btn_class_p;
    }
    else if(ajax_status.responseText == "tl_md_ready") {
      setButtonState("video_button", true, "record video start");
      setButtonState("image_button", false, "record image", "im");
      setButtonState("timelapse_button", false, "timelapse stop", "tl 0");
      setButtonState("md_button", false, "motion detection stop", "md 0");
      setButtonState("halt_button", true, "stop camera");
      document.getElementById("preview_select").disabled = false;
      document.getElementById("video_button").className = btn_class_p;
      document.getElementById("timelapse_button").className = btn_class_a;
      document.getElementById("md_button").className = btn_class_a;
      document.getElementById("image_button").className = btn_class_p;
      halted = 0;
    }
    else if(ajax_status.responseText == "video") {
      setButtonState("video_button", false, "record video stop", "ca 0");
      setButtonState("image_button", false, "record image", "im");
      setButtonState("timelapse_button", false, "timelapse start", "tl 1");
      setButtonState("md_button", true, "motion detection start");
      setButtonState("halt_button", true, "stop camera");
      document.getElementById("preview_select").disabled = true;
      document.getElementById("video_button").className = btn_class_a;
      document.getElementById("timelapse_button").className = btn_class_p;
      document.getElementById("md_button").className = btn_class_p;
      document.getElementById("image_button").className = btn_class_p;
    }
    else if(ajax_status.responseText == "md_video") {
      setButtonState("video_button", true, "record video stop");
      setButtonState("image_button", false, "record image", "im");
      setButtonState("timelapse_button", false, "timelapse start", "tl 1");
      setButtonState("md_button", true, "recording video...");
      setButtonState("halt_button", true, "stop camera");
      document.getElementById("preview_select").disabled = true;
      document.getElementById("video_button").className = btn_class_a;
      document.getElementById("timelapse_button").className = btn_class_p;
      document.getElementById("md_button").className = btn_class_a;
      document.getElementById("image_button").className = btn_class_p;
    }
    else if(ajax_status.responseText == "tl_video") {
      setButtonState("video_button", false, "record video stop", "ca 0");
      setButtonState("image_button", true, "record image");
      setButtonState("timelapse_button", false, "timelapse stop", "tl 0");
      setButtonState("md_button", true, "motion detection start");
      setButtonState("halt_button", true, "stop camera");
      document.getElementById("preview_select").disabled = false;
      document.getElementById("video_button").className = btn_class_a;
      document.getElementById("timelapse_button").className = btn_class_a;
      document.getElementById("md_button").className = btn_class_p;
      document.getElementById("image_button").className = btn_class_p;
    }
    else if(ajax_status.responseText == "tl_md_video") {
      setButtonState("video_button", false, "record video stop", "ca 0");
      setButtonState("image_button", true, "record image");
      setButtonState("timelapse_button", false, "timelapse stop", "tl 0");
      setButtonState("md_button", true, "recording video...");
      setButtonState("halt_button", true, "stop camera");
      document.getElementById("preview_select").disabled = false;
      document.getElementById("video_button").className = btn_class_a;
      document.getElementById("timelapse_button").className = btn_class_a;
      document.getElementById("md_button").className = btn_class_a;
      document.getElementById("image_button").className = btn_class_p;
    }
    else if(ajax_status.responseText == "image") {
      setButtonState("video_button", true, "record video start");
      setButtonState("image_button", true, "recording image");
      setButtonState("timelapse_button", true, "timelapse start");
      setButtonState("md_button", true, "motion detection start");
      setButtonState("halt_button", true, "stop camera");
      document.getElementById("preview_select").disabled = false;
      document.getElementById("image_button").className = btn_class_a;
    }
    else if(ajax_status.responseText == "halted") {
      setButtonState("video_button", true, "record video start");
      setButtonState("image_button", true, "record image");
      setButtonState("timelapse_button", true, "timelapse start");
      setButtonState("md_button", true, "motion detection start");
      setButtonState("halt_button", false, "start camera", "ru 1");
      document.getElementById("preview_select").disabled = false;
      document.getElementById("video_button").className = btn_class_p;
      document.getElementById("timelapse_button").className = btn_class_p;
      document.getElementById("md_button").className = btn_class_p;
      document.getElementById("video_button").className = btn_class_p;
      document.getElementById("timelapse_button").className = btn_class_p;
      document.getElementById("md_button").className = btn_class_p;
      document.getElementById("image_button").className = btn_class_p;
      halted = 1;
    }
    else if(ajax_status.responseText.substr(0,5) == "Error") {
      alert("Error in RaspiMJPEG: " + ajax_status.responseText.substr(7) + "\nRestart RaspiMJPEG (./RPi_Cam_Web_Interface_Installer.sh start) or the whole RPi.");
    }

    updatePreview();
    reload_ajax(ajax_status.responseText);
  }
};
