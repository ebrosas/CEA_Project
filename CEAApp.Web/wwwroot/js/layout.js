$(function () {
    $("#btnToggleUserFunction").on("click", ShowHideUserFunctionMenu);
    $("#btnToggleReportFunction").on("click", ShowHideReportFunctionMenu);    
    $("#btnToggleAdmin").on("click", ShowHideAdminMenu);
});

function ShowHideUserFunctionMenu(menuToClick) {
    let plusMinusLink = $("#lnkPlusMinusUF");

    if (plusMinusLink != null) {
        if (plusMinusLink.hasClass("fa-plus-circle")) {
            plusMinusLink.removeClass("fa-plus-circle").addClass("fa-minus-circle");
        }
        else {
            plusMinusLink.removeClass("fa-minus-circle").addClass("fa-plus-circle");
        }
    }

    if (menuToClick != null) {
        $.when($('#mnuUserFunction .nav-second-level').slideToggle("slow")).done(function () {
            $('#' + menuToClick).click();
        });
    }
    else
        $(plusMinusLink).parent().parent().next().slideToggle("slow");
}

function ShowHideReportFunctionMenu(menuToClick) {
    let plusMinusLink = $("#lnkPlusMinusRF");

    if (plusMinusLink != null) {
        if (plusMinusLink.hasClass("fa-plus-circle")) {
            plusMinusLink.removeClass("fa-plus-circle").addClass("fa-minus-circle");
        }
        else {
            plusMinusLink.removeClass("fa-minus-circle").addClass("fa-plus-circle");
        }
    }

    if (menuToClick != null) {
        $.when($('#mnuReportFunction .nav-second-level').slideToggle("slow")).done(function () {
            $('#' + menuToClick).click();
        });
    }
    else
        $(plusMinusLink).parent().parent().next().slideToggle("slow");
}

function ShowHideAdminMenu(menuToClick) {
    let plusMinusLink = $("#lnkPlusMinus");

    if (plusMinusLink != null) {
        if (plusMinusLink.hasClass("fa-plus-circle")) {
            plusMinusLink.removeClass("fa-plus-circle").addClass("fa-minus-circle");
        }
        else {
            plusMinusLink.removeClass("fa-minus-circle").addClass("fa-plus-circle");
        }
    }

    if (menuToClick != null) {
        $.when($('#mnuAdmin .nav-second-level').slideToggle("slow")).done(function () {
            $('#' + menuToClick).click();
        });
    }
    else
        $(plusMinusLink).parent().parent().next().slideToggle("slow");
}