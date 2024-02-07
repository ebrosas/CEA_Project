
$(() => {

    // Set the current container
    gContainer = $('.formWrapper');

    HideLoadingPanel(gContainer);
    HideErrorMessage();

    // Hide all error alerts
    $('.errorPanel').attr("hidden", "hidden");       

    $("#btnBack").on('click', handleSecurityButtonClick);

});

function handleSecurityButtonClick() {
    var btn = $(this);
    var hasError = false;

    // Hide all tool tips
    $('[data-bs-toggle="tooltip"]').tooltip('hide');

    // Hide all error messages
    HideErrorMessage();
    HideToastMessage();

    switch ($(btn)[0].id) {
        case "btnBack":
            // Set the controller action method of the Back button
            let callerFormVal = GetStringValue($("#hidCallerForm").val());

            if (callerFormVal == PageControllerMapping.CEARequisition.toString()) {
                // Open the Requisition Inquiry page
                location.href = "/UserFunctions/Project/".concat(PageControllerMapping.RequisitionInquiry);
            }
            else if (callerFormVal == PageControllerMapping.ProjectDetail.toString()) {
                // Open the Requisition Inquiry page
                location.href = "/UserFunctions/Project/".concat(PageControllerMapping.ProjectDetail);
            }
            else {
                // Open the Project Inquiry page
                location.href = "/UserFunctions/Project/".concat(PageControllerMapping.ProjectInquiry);
            }
            break;
    }
}