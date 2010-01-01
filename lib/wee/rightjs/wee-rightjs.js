var wee = {};

wee._update_elements = function(e) {
  var id = e.get('id');
  if (id)
    $(id).update(e);
  else
    e.insertTo(document.body);
};

wee._update_callback = function(r) {
  new Element('div', {html: r.text}).subNodes().each(wee._update_elements);
};

wee.update = function(url) {
  new Xhr(url, {method: 'get'}).onSuccess(wee._update_callback).send();
  return false;
};
