// 2

function selectors_for(h1_title) {
  if (!h1_title) return null;
  s = 'h1:contains("'+h1_title+'")'
  t = null;
  for (i=0; i<20;i++)
    t = (t ? t+',' : '') + (s += '+*')
  return t;
}

function todos_between(start_title, stop_title) {
  return $(selectors_for(start_title))
    .not(selectors_for(stop_title))
    .filter('ul')
    .find('li');
}

function decorate_todos(items, img_src) {
  items.prepend('<img src="'+img_src+'"/>');
}

$(document).ready(function(){
  $('h1')
    .css('border-bottom','solid 1px #666')
    .not(':first')
    .css('margin-top','30px')
  ;
  decorate_todos(todos_between('MUST'  ,'SHOULD'), 'img/pin-red.png');
  decorate_todos(todos_between('SHOULD','COULD' ), 'img/pin-yellow.png');
  decorate_todos(todos_between('COULD' ,null    ), 'img/pin-blue.png');
});

