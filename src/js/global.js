var btn_pi = document.getElementById('pi');
var btn_access = document.getElementById('access');
var btn_isi = document.getElementById('isi');
var btn_ref = document.getElementById('ref');

btn_pi.addEventListener('click', function () {
  CLMPlayer.gotoSlide('oceasset_brandpi', null, null);
});

btn_access.addEventListener('click', function () {
  CLMPlayer.gotoSlide(null, 'XX_slide.html', null);
});

btn_isi.addEventListener('click', function () {
  CLMPlayer.gotoSlide(null, 'XX_slide.html', null);
});

btn_ref.addEventListener('click', function () {
  CLMPlayer.gotoSlide(null, 'XX_slide.html', null);
});
