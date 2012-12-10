// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(document).ready(function() {

  editableTranslations();
  editableKeyTranslations();

  $('.accept_translation').live('click', function(){
    $.ajax({
      type: 'POST',
      url: Routes.translation_center_translation_accept_path($(this).attr('data-translation-id'), {format: 'js'})
    });
  });

  $('.unaccept_translation').live('click', function(){
    $.ajax({
      type: 'POST',
      url: Routes.translation_center_translation_unaccept_path($(this).attr('data-translation-id'), {format: 'js'})
    });
  });

  $('.sort_by_votes').live('click', function(){
    $.ajax({
      type: 'GET',
      url: Routes.translation_center_translation_key_translations_path($(this).attr('data-key-id'), {format: 'js'}),
      data: {sort_by: 'votes'}
    });
  });

  $('.translations_tab, .sort_by_date').live('click', function(){
    $.ajax({
      type: 'GET',
      url: Routes.translation_center_translation_key_translations_path($(this).attr('data-key-id'), {format: 'js'})
    });
  });
  
  $('.translations_vote').live('mouseover',
    function() {
      $(this).addClass('badge-success');
  });

  $('.translations_vote').live('mouseout',
    function() {
      if($(this).attr('voted') == 'false')
        $(this).removeClass('badge-success');
    }
  );

  $('.translations_vote').live('click', function() {
    // vote
    if($(this).attr('voted') == 'false')
    {
      $(this).addClass('badge-success');
      $(this).attr('voted', 'true')
      // TODO use I18n.t
      $(this).text('Unvote');
      $.ajax({
        type: 'POST',
        url: Routes.translation_center_translation_vote_path($(this).attr('data-translation-id'), {format: 'js'})
      });
     

    }
    // unvote
    else
    {
      $(this).removeClass('badge-success');
      $(this).attr('voted', 'false') 
      // TODO use I18n.t
      $(this).text('Vote');
      $.ajax({
        type: 'POST',
        url: Routes.translation_center_translation_unvote_path($(this).attr('data-translation-id'), {format: 'js'})
      });
    }
  });

});

function moveToNextKey(key_id){
  var translation_key = $('li.translation_key[data-key-id=' + key_id + ']')
  var translations_listing = $('.tab-pane#' + translation_key.attr('data-key-id'));
  translations_listing.removeClass('active');
  translation_key.fadeOut();
  var next_key = translation_key.next();
  next_key.addClass('active');
  next_key.effect("highlight", {}, 3000);
  $('.tab-pane#' + next_key.attr('data-key-id')).addClass('active');
}

function editableTranslations(){

  $.each($('.user_translation'), function(){
    var key_id = $(this).attr('data-key-id');

    $(this).editable(Routes.translation_center_translation_key_update_translation_path(key_id, {format: 'json'}), {
      method: 'POST',
      onblur : 'submit',
      // TODO use I18n.t for translations
      placeholder : 'click to add or edit your translation',
      tooltip     : 'click to add or edit your translation',
      callback : function(value, settings) {
        
        if(Filter.key() == 'untranslated')
        {
          var count = parseInt($('#untranslated_keys_count').text().replace('(', '').replace(')', '')) - 1;
          $('#untranslated_keys_count').text('(' + count +  ')');
          var count = parseInt($('#pending_keys_count').text().replace('(', '').replace(')', '')) + 1;
          $('#pending_keys_count').text('(' + count +  ')');
          moveToNextKey($(this).attr('data-key-id'));
        }else if(Filter.key() == 'all')
        {
          $('li.translation_key[data-key-id=' + key_id + ']').children('div').removeClass('badge-important').addClass('badge-warning');
        }
      }

      
    });

  });

}

function editableKeyTranslations(){

  $.each($('.key_editable'), function(){
    var key_id = $(this).attr('data-key-id');

    $(this).editable(Routes.translation_center_translation_key_path(key_id, {format: 'json'}), {
      method: 'PUT',
      onblur : 'submit',
      // TODO use I18n.t for translations
      tooltip     : 'Click to edit translation key'
    });

  });

}