// #region Declare Constants
interface RequisitionSearchCriteria {
    projectNo?: string;
    requisitionNo?: string;
    expenditureType?: string;
    fiscalYear?: number;
    statusCode?: string;
    costCenter?: string;
    empNo?: number;
    filterToUser?: boolean;
    keywords?: string;
}
// #endregion

// #region Document Initialization
$(() => {

    // Set the current container
    gContainer = $('.formWrapper');

    HideLoadingPanel(gContainer);
    HideErrorMessage();

    // Hide all error alerts
    $('.errorPanel').attr("hidden", "hidden");

    // #region Initialize event handlers
    $("#btnCreate, #btnSave, #btnEdit, #btnReset").on('click', handleDetailActionButtons);
    // #endregion

    // #region Initialize controls

    // Restrict input for "Budgeted Project Amount" field to accept numbers only
    $('input[name="ProjectAmount"').attr("onkeypress", "return OnlyNumberKey(event)");

    // Set the controller action method of the Back button
    let callerFormVal = $("#hidCallerForm").val();
    let url = $('a[class~="backButton"').attr("href");
    if (callerFormVal == "RequisitionInquiry") {
        $('a[class~="backButton"').attr("href", url!.concat("/Project/RequisitionInquiry"));
    }
    else if (CheckIfNoValue(callerFormVal)) {        
        if (!url?.includes("UserFunctions")) {
            $('a[class~="backButton"').removeAttr("href");
            $('a[class~="backButton"').attr("href", url!.concat("/UserFunctions/Project/RequisitionInquiry"));
        }
    }
    // #endregion

    // #region Initialize form secuity
    let userName = GetStringValue($("#hidUserName").val());
    let formCode = GetStringValue($("#hidFormCode").val());

    // Check first if user credentials was already been initialize
    let userCredential = GetDataFromSession("UserCredential");
    if (!CheckIfNoValue(userCredential)) {
        const model = JSON.parse(userCredential!);

        // Reinstantiate global variable 
        gCurrentUser.empNo = model.empNo;
        gCurrentUser.empName = model.empName;
        gCurrentUser.email = model.email;
        gCurrentUser.userName = model.userName;
        gCurrentUser.costCenter = model.costCenter;
        gCurrentUser.costCenterName = model.costCenterName;  

        // Get user access information
        GetUserFormAccess(formCode, model.costCenter, model.empNo, PageNameList.ProjectDetail);
    }
    else {
        GetUserCredential(userName, formCode, PageNameList.ProjectInquiry);
    }
    // #endregion

    // Clear the form
    resetDetailForm();

    // Show toast message if necessary
    if (!CheckIfNoValue($("input[name='ToastNotification']").val())) {
        ShowToastMessage(toastTypes.success, $("input[name='ToastNotification']").val(), "Success Notification");

        // Clear the notification
        $("input[name='ToastNotification']").val("");
    }

    let projectNo: string = GetQueryStringValue("projectNo")!;
    if (CheckIfNoValue(projectNo)) {
        //let savedProjectNo = $("#hidProjectNo").val()?.toString();
        let savedProjectNo = $('input[name="ProjectNo"]').val()?.toString();
        if (savedProjectNo !== undefined)
            loadRequisitionTable(savedProjectNo.trim(), false);
    } else {
        loadRequisitionTable(projectNo.trim(), false);
    }   
});
// #endregion

// #region Private Methods
function handleDetailActionButtons() {
    var btn = $(this);
    var hasError = false;

    // Hide all error messages
    HideErrorMessage();
    HideToastMessage();

    // Hide all tool tips
    $('[data-bs-toggle="tooltip"]').tooltip('hide');

    switch ($(btn)[0].id) {
        case "btnCreate":
            openCEAForm();
            break;

        case "btnSave":
            if (HasAccess(gUserAccess.userFrmCRUDP, FormAccessIndex.Create))
                detailSaveButtonClick();
            else
                ShowToastMessage(toastTypes.error, CONST_CREATE_DENIED, "Access Denied");
            break;

        case "btnEdit":
            if (HasAccess(gUserAccess.userFrmCRUDP, FormAccessIndex.Update))
                detailEditButtonClick();
            else
                ShowToastMessage(toastTypes.error, CONST_UPDATE_DENIED, "Access Denied");
            break;

        case "btnReset":
            detailResetButtonClick();
            break;
    }
}

function resetDetailForm() {
    try {

        // Display loading panel
        ShowLoadingPanel(gContainer, 1, 'Refreshing the form, please wait...');

        // Hide all error alerts
        HideErrorMessage();
        $('.errorPanel').attr("hidden", "hidden");

        // Hide all tool tips
        $('[data-bs-toggle="tooltip"]').tooltip('hide');

        // Toggle buttons
        $("#btnEdit").removeAttr("disabled");                                   // Edit button
        $("#btnEdit").removeClass("btn-outline-danger").addClass("btn-danger").addClass("text-white").addClass("border-0");

        $("#btnCreate").removeAttr("disabled");                                 // Create button
        $("#btnCreate").removeClass("btn-outline-primary").addClass("btn-primary").addClass("text-white").addClass("border-0");

        $('[class*="backButton"]').removeClass("disabled");                     // Back button  

        $("#btnSave").attr("disabled", "disabled");                             // Save button
        $("#btnSave").removeClass("btn-success").removeClass("text-white").addClass("btn-outline-success");

        // Disable editable controls
        $('[class*="editable"]').attr("disabled", "disabled");

        // Reset dataTable
        populateRequestTable(null);

        // Move to the top of the page
        window.scrollTo(0, 0);

        $("#btnHiddenReset").click();

        let projectNo = $("#hidProjectNo").val() as string;
        if (!CheckIfNoValue(projectNo))
            loadRequisitionTable(projectNo.trim(), false);
    }
    catch (error) {
        ShowErrorMessage("The following error has occured while refreshing the form: " + "<b>" + error.message + "</b>")
    }
    finally {
        HideLoadingPanel(gContainer);
        gContainer = $('.formWrapper');
    }       
}

function populateRequestTable(data: any) {
    var dataset = data;
    if (dataset == "undefined" || dataset == null) {
        // Get DataTable API instance
        var table = $("#requisitionTable").dataTable().api();
        table.clear().draw();
        HideLoadingPanel(gContainer);
    }
    else {
        let reportTitle = "CEA / MRE Requisition Summary Report";

        $("#requisitionTable")
            .on('init.dt', function () {    // This event will fire after loading the data in the table
                HideLoadingPanel(gContainer);

                // #region Initialize button visibility based on user's access permission
                // Show "Create New" button if user has insert access
                if (HasAccess(gUserAccess.userFrmCRUDP, FormAccessIndex.Create))
                    $("#btnCreate").removeAttr("hidden"); 

                // Show "Edit" and "Save" buttons if user has update access
                if (HasAccess(gUserAccess.userFrmCRUDP, FormAccessIndex.Update)) {
                    $("#btnEdit").removeAttr("hidden"); 
                    $("#btnSave").removeAttr("hidden"); 
                }
                // #endregion
            })
            .DataTable({
                data: dataset,
                processing: true,           // To show progress bar 
                serverSide: false,          // To enable processing server side processing (e.g. sorting, pagination, and filtering)
                orderMulti: false,          // To disable mutiple column sorting
                destroy: true,              // To destroy an old instance of the table and to initialise a new one
                scrollX: true,              // To enable horizontal scrolling
                language: {
                    emptyTable: "No records found in the database."
                },
                lengthMenu: [[5, 10, 20, 50, 100, -1], [5, 10, 20, 50, 100, "All"]],
                pageLength: 10,             // Number of rows to display on a single page when using pagination.
                order: [[1, 'asc']],
                drawCallback: function () {
                    $('.lnkReqNo').on('click', getRequisitionDetail);
                },
                dom: "<'row' <'col-sm-3'l> <'col-sm-6 text-center'B> <'col-sm-3'f> >" +
                    "<'row'<'col-sm-12 col-md-12'tr>>" +
                    "<'row'<'col-xs-12 col-sm-5 col-md-5'i><'col-xs-12 col-sm-7 col-md-7'p>>",               
                buttons: [
                    {
                        text: '<i class="fas fa-file-export fa-lg fa-fw"></i>',
                        extend: 'copy',
                        className: 'btn btn-light tableButton',
                        titleAttr: 'Copy data to clipboard',
                    },
                    {
                        text: '<i class="fas fa-file-excel fa-lg fa-fw"></i>',
                        extend: 'excel',
                        className: 'btn btn-light tableButton',
                        titleAttr: 'Export results to Excel',
                        title: reportTitle
                    },
                    {
                        text: '<i class="fas fa-file-csv fa-lg fa-fw"></i>',
                        extend: 'csv',
                        className: 'btn btn-light tableButton',
                        titleAttr: 'Export results to CSV',
                        title: reportTitle
                    },
                    {
                        text: '<i class="fas fa-print fa-lg fa-fw"></i>',
                        extend: 'print',
                        className: 'btn btn-light tableButton',
                        titleAttr: 'Print results'
                    }
                ],
                columns: [
                    {
                        data: "requisitionNo"
                    },
                    {
                        data: "requisitionDate",
                        render: function (data) {
                            return '<label style="width: 150px;">' + moment(data).format('DD-MMM-YYYY') + '</label>';
                        }
                    },
                    {
                        data: "description",
                        render: $.fn.dataTable.render.text()
                    },
                    {
                        data: "dateofComission",
                        render: function (data) {
                            return '<label style="width: 150px;">' + moment(data).format('DD-MMM-YYYY') + '</label>';
                        }
                    },
                    {
                        data: "amount",
                        render: $.fn.dataTable.render.number(',', '.', 3)
                    },
                    {
                        data: "approvalStatus",
                        render: function (data) {
                            return '<label style="width: 230px;">' + data + '</label>';
                        }
                    },
                    {
                        data: "usedAmount",
                        render: $.fn.dataTable.render.number(',', '.', 3)
                    },
                    {
                        data: "createDate",
                        render: function (data) {
                            return '<label style="width: 140px;">' + moment(data).format('DD-MMM-YYYY') + '</label>';
                        }
                    },
                    {
                        data: "createdByName",
                        render: function (data) {
                            return '<label style="width: 350px;">' + data + '</label>';
                        }
                    },
                    {
                        data: "requisitionID"
                    }
                ],
                columnDefs: [
                    {
                        targets: "centeredColumn",
                        className: 'dt-body-center'
                    },
                    {
                        targets: 0,
                        render: function (data, type, row) {
                            return '<label style="width: 130px;">' + '<a href="javascript:void(0)" class="lnkReqNo gridLink" data-requisitionno=' + row.requisitionNo + '> ' + row.requisitionNo + '</a>' + '</label>';
                        }
                    },
                    {
                        targets: "hiddenColumn",
                        visible: false
                    },
                    {
                        targets: "doNotOrder",
                        orderable: false
                    }
                ]
            });
    }
}

function getRequisitionDetail() {
    let requisitionNo: string = $(this).text().trim();

    if (!CheckIfNoValue(requisitionNo)) {
        ShowLoadingPanel(gContainer, 1, 'Loading requisition details, please wait...');

        // Open the Project Details View
        location.href = "/UserFunctions/Project/CEARequisition?requisitionNo=".concat(requisitionNo)
            .concat("&actionType=0")
            .concat("&callerForm=").concat(PageControllerMapping.ProjectDetail.toString());
    }
}

function openCEAForm() {
    let projectNo: string = ($("#hidProjectNo").val() as string).trim();

    if (!CheckIfNoValue(projectNo)) {
        ShowLoadingPanel(gContainer, 1, 'Opening CEA requisition form, please wait...');

        // Open the Project Details View
        location.href = "/UserFunctions/Project/CEARequisition?projectNo=".concat(projectNo)
            .concat("&actionType=2")
            .concat("&user_empno=").concat(gCurrentUser.empNo.toString())
            .concat("&user_empname=").concat(gCurrentUser.empName.trim())
            .concat("&callerForm=").concat(PageControllerMapping.ProjectDetail.toString());
    }
}

function displayError(obj, errText, focusObj) {
    var alert = $(obj).find(".alert");

    if ($(alert).find(".errorText") != undefined)
        $(alert).find(".errorText").html(errText);

    if (obj != undefined)
        $(obj).removeAttr("hidden");

    //if ($(alert).attr("hidden") == "hidden")
    //    $(alert).removeAttr("hidden");
    $(alert).show();

    if (focusObj != undefined)
        $(focusObj).focus();
}
// #endregion

// #region Action Button Methods
function detailResetButtonClick() {

    resetDetailForm();
}

function detailEditButtonClick() {

    // Enable controls
    $('[class*="editable"]').removeAttr("disabled");

    // Toggle buttons
    $("#btnEdit").attr("disabled", "disabled");                                 // Edit button
    $("#btnEdit").removeClass("btn-danger").removeClass("text-white").removeClass("border-0").addClass("btn-outline-danger");

    $("#btnCreate").attr("disabled", "disabled");                               // Create button
    $("#btnCreate").removeClass("btn-primary").removeClass("text-white").removeClass("border-0").addClass("btn-outline-primary");

    $('[class*="backButton"]').addClass("disabled");                            // Back button  

    $("#btnSave").removeAttr("disabled");                                       // Save button
    $("#btnSave").removeClass("btn-outline-success").addClass("btn-success").addClass("text-white");

    // Hide all tool tips
    $('[data-bs-toggle="tooltip"]').tooltip('hide');
}

function detailSaveButtonClick() {
    let hasError = false;

    // Hide all tool tips
    $('[data-bs-toggle="tooltip"]').tooltip('hide');

    // #region Validate Inputs

    // Check Fiscal Year
    if (CheckIfNoValue($('select[name="FiscalYear"').val())) {
        displayError($('#FiscalYearError'), "<b>" + $(".fieldLabel label[data-field='FiscalYear']").text() + "</b> is required and cannot be left blank.", $('select[name="FiscalYear"'));
        hasError = true;
    }
    else {
        if ($('#FiscalYearError').attr("hidden") == undefined)
            $('#FiscalYearError').attr("hidden", "hidden");
    }

    // Check Cost Center
    if (CheckIfNoValue($('select[name="CostCenter"').val())) {
        displayError($('#CostCenterError'), "<b>" + $(".fieldLabel label[data-field='CostCenter']").text() + "</b> is required and cannot be left blank.", $('select[name="CostCenter"'));
        hasError = true;
    }
    else {
        if ($('#CostCenterError').attr("hidden") == undefined)
            $('#CostCenterError').attr("hidden", "hidden");
    }

    // Check Expenditure Type
    if (CheckIfNoValue($('select[name="ExpenditureType"').val())) {
        displayError($('#ExpenditureTypeError'), "<b>" + $(".fieldLabel label[data-field='ExpenditureType']").text() + "</b> is required and cannot be left blank.", $('select[name="ExpenditureType"'));
        hasError = true;
    }
    else {
        if ($('#ExpenditureTypeError').attr("hidden") == undefined)
            $('#ExpenditureTypeError').attr("hidden", "hidden");
    }

    // Check Expected Project Date
    if (CheckIfNoValue($('input[name="ExpectedProjectDate"').val())) {
        displayError($('#ExpectedProjectDateError'), "<b>" + $(".fieldLabel label[data-field='ExpectedProjectDate']").text() + "</b> is required and cannot be left blank.", $('input[name="ExpectedProjectDate"'));
        hasError = true;
    }
    else {
        if ($('#ExpectedProjectDateError').attr("hidden") == undefined)
            $('#ExpectedProjectDateError').attr("hidden", "hidden");
    }

    // Check Description
    if (CheckIfNoValue($('textarea[name="Description"').val())) {
        displayError($('#DescriptionError'), "<b>" + $(".fieldLabel label[data-field='Description']").text() + "</b> is required and cannot be left blank.", $('textarea[name="Description"'));
        hasError = true;
    }
    else {
        if ($('#DescriptionError').attr("hidden") == undefined)
            $('#DescriptionError').attr("hidden", "hidden");
    }

    // Check Detailed Description
    if (CheckIfNoValue($('textarea[name="DetailDescription"').val())) {
        displayError($('#DetailDescriptionError'), "<b>" + $(".fieldLabel label[data-field='DetailDescription']").text() + "</b> is required and cannot be left blank.", $('textarea[name="DetailDescription"'));
        hasError = true;
    }
    else {
        if ($('#DetailDescriptionError').attr("hidden") == undefined)
            $('#DetailDescriptionError').attr("hidden", "hidden");
    }

    // Check Project Amount
    if (GetIntValue($('input[name="ProjectAmount"').val()) == 0) {
        displayError($('#ProjectAmountError'), "<b>" + $(".fieldLabel label[data-field='ProjectAmount']").text() + "</b> is required and cannot be left blank.", $('input[name="ProjectAmount"'));
        hasError = true;
    }
    else {
        if ($('#ProjectAmountError').attr("hidden") == undefined)
            $('#ProjectAmountError').attr("hidden", "hidden");
    }
    // #endregion

    if (!hasError) {
        ShowLoadingPanel(gContainer, 1, 'Saving information, please wait...');
        $("#btnHiddenSubmit").click();
    }
}
// #endregion

// #region Database Methods
function loadRequisitionTable(projectNo: string, restoreData: boolean, param?: RequisitionSearchCriteria) {
    try {

        const searchFilter = {
            projectNo: projectNo,
            requisitionNo: "",
            expenditureType: "",
            fiscalYear: 0,
            statusCode: "",
            costCenter: "",
            empNo: 0,
            filterToUser: 0,
            keyWords: ""
        };

        if (restoreData) {
            searchFilter.projectNo = param!.projectNo!.toString();
        }

        // Save filter criteria to session storage
        //SaveDataToSession("searchCriteria", JSON.stringify(searchFilter));

        $.ajax({
            url: "/UserFunctions/Project/LoadRequisitionList",
            type: "GET",
            dataType: "json",
            contentType: "application/json; charset=utf-8",
            cache: false,
            async: true,
            data: searchFilter,
            success:
                function (response, status) {
                    if (status == "success") {
                        populateRequestTable(response.data);
                    }
                    else {
                        HideLoadingPanel(gContainer);
                        ShowErrorMessage("Unable to load project details from the database, please contact ICT for technical support.");
                    }
                },
            error:
                function (err) {
                    HideLoadingPanel(gContainer);
                    ShowErrorMessage("The following error has occured while executing loadRequisitionTable(): " + err.responseText);
                }
        });

    } catch (error) {
        HideLoadingPanel(gContainer);
        ShowErrorMessage("The following error has occured while loading the data to the search results table: " + "<b>" + error.message + "</b>")
    }
}
// #endregion