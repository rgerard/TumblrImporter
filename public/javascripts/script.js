// remap jQuery to $
(function($){
	//Tabs
	$(".tab_content:not(.tab_content:first)").hide(); //Hide all content except first
	$("ul.tabs li:first").addClass("active"); //Activate first tab
	
	//On Click Event
	$("ul.tabs li a").click(function() {
		$("ul.tabs li").removeClass("active"); //Remove any "active" class
		$(this).parent().addClass("active"); //Add "active" class to selected tab
		var activeTab = $(this).attr("href"); //Find the rel attribute value to identify the active tab + content
		$(".tab_content:visible").slideUp('500', function() {
			$(activeTab).slideDown('500'); // Slide in the active content
		});
		return false;
	});
	
	// Tipsy
	$('.tooltip').tipsy({gravity: 's', offset: 2});
	
	// Fancybox
	$('a.fancybox').fancybox({
		'opacity'		: true,
		'overlayShow'	: false,
		'transitionIn'	: 'elastic',
		'transitionOut'	: 'elastic'
	});
})(window.jQuery);

function validateForm() {
    var feed = document.forms["migrate"]["feed"].value;
    var blog = document.forms["migrate"]["blog"].value;

    if (feed==null || feed=="" || blog==null || blog=="") {
        alert("Please fill in both the URL's to your RSS feed and to your Tumblr blog");
        return false;
    }
}



















