var wee = {};

wee._update_elements = function(_,e) {
  var src = jQuery(e);
  var id = src.attr('id'); 
  if (id)
    jQuery('#'+id).replaceWith(src);
  else
    jQuery('html > body').append(src); 
};

wee._update_callback = function(data) {
  jQuery(data).each(wee._update_elements); 
};

wee.update = function(url) {
  jQuery.get(url, {}, wee._update_callback, 'html');
  return false;
};
