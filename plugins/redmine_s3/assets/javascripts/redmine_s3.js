/*
 * This script handles thumbnail image missing errors
 */

$(function() {
    $('.attachments .thumbnails img').one('error', function() {
        $.ajax({
            dataType: 'JSON',
            url: $(this).attr('src') + '?update_thumb=true',
            context: this
        }).done(function(data, status, response) {
            $(this).attr('src', response.responseJSON.src);
        });
    });
});
