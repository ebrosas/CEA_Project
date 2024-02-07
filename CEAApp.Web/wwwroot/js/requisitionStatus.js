// #region Fields
class StatusSearchCriteria {
    constructor() {
        this.requisitionID = 0;
        this.ceaNo = "";
    }
}
let statusListCount = 0;
let isUseNewWF = false;
// #endregion
// #region Document Initialization
$(() => {
    // Set the current container
    gContainer = $('.formWrapper');
    HideLoadingPanel(gContainer);
    HideErrorMessage();
    // Hide all error alerts
    $('.errorPanel').attr("hidden", "hidden");
    //#region Set the controller action method of the Back button
    let callerFormVal = $("#hidCallerForm").val();
    let url = $('a[class~="backButton"').attr("href");
    // Append any query string values
    if (!CheckIfNoValue($("#hidQueryString").val())) {
        url = url.concat($("#hidQueryString").val());
    }
    if (callerFormVal == "RequisitionDetail") {
        $('a[class~="backButton"').attr("href", url.replace("RequisitionInquiry", "CEARequisition"));
    }
    // #endregion
    // Initialize global variables
    isUseNewWF = GetBooleanValue($("#hidUseNewWF").val());
    //if (isUseNewWF) {
    //    // Show the new workflow status
    //    $("#divRequestStatus").prop("hidden", true);
    //    $("#divWorkflowStatus").prop("hidden", false);
    //}
    resetStatusForm();
    searchButtonStatus();
});
// #endregion
// #region Functional Methods
function resetStatusForm() {
    // Reset dataTable
    populateStatusTable(null);
    populateWFStatusTable(null);
    // Reset the buttons
    $('#btnSearch').removeAttr("disabled");
    $('span[class~="spinicon"]').attr("hidden", "hidden"); // Hide spin icon
    $('span[class~="normalicon"]').removeAttr("hidden"); // Show normal icon
    // Move to the top of the page
    window.scrollTo(0, 0);
    $("#btnHiddenReset").click();
}
function populateStatusTable(data) {
    var dataset = data;
    if (dataset == "undefined" || dataset == null) {
        // Get DataTable API instance
        var table = $("#statusTable").dataTable().api();
        table.clear().draw();
        HideLoadingPanel(gContainer);
    }
    else {
        let reportTitle = "Requisitions Summary Report";
        // Save the table record count
        statusListCount = dataset.length;
        $("#statusTable")
            .on('init.dt', function () {
            HideLoadingPanel(gContainer);
            if (statusListCount > 0)
                $('span[class~="recordCount"').html("Found <b>" + statusListCount.toString() + "</b> record(s).");
            else
                $('span[class~="recordCount"').text("No records found!");
            // Reset the buttons
            $('#btnSearch').removeAttr("disabled");
            $('span[class~="spinicon"]').attr("hidden", "hidden"); // Hide spin icon
            $('span[class~="normalicon"]').removeAttr("hidden"); // Show normal icon
        })
            .DataTable({
            data: dataset,
            processing: true,
            serverSide: false,
            orderMulti: false,
            destroy: true,
            scrollX: true,
            language: {
                emptyTable: "No records found in the database."
            },
            lengthMenu: [[5, 10, 20, 50, 100, -1], [5, 10, 20, 50, 100, "All"]],
            pageLength: 10,
            order: [[7, 'asc'], [8, 'asc']],
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
                    data: "approvalGroup",
                    render: function (data) {
                        return '<label class="d-inline-block text-truncate ps-2 text-start text-primary fw-bold" style="width: 300px;">' + data + '</label>';
                    }
                },
                {
                    data: "approverEmpName"
                },
                {
                    data: "currentStatus",
                    render: function (data) {
                        return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 220px;">' + data + '</label>';
                    }
                    //render: function (data, type, row) {
                    //    if (row.statusHandlingCode == 'Draft') {
                    //        return '<div class="text-start ps-2" style="width: 230px;"><label class="bg-info rounded-pill text-white py-1 px-3" style="width: auto; height: auto;">' + data + '</label></div>';
                    //    }
                    //    else if (row.statusHandlingCode == 'Approved') {
                    //        return '<div class="text-start ps-2" style="width: 230px;"><label class="bg-success rounded-pill text-white py-1 px-3" style="width: auto; height: auto;">' + data + '</label></div>';
                    //    }
                    //    else if (row.statusHandlingCode == 'Cancelled') {
                    //        return '<div class="text-start ps-2" style="width: 230px;"><label class="bg-warning rounded-pill text-white py-1 px-3" style="width: auto; height: auto;">' + data + '</label></div>';
                    //    }
                    //    else if (row.statusHandlingCode == 'Rejected') {
                    //        return '<div class="text-start ps-2" style="width: 230px;"><label class="bg-danger rounded-pill text-white py-1 px-3" style="width: auto; height: auto;">' + data + '</label></div>';
                    //    }
                    //    else if (data == 'Closed') {
                    //        return '<div class="text-start ps-2" style="width: 230px;"><label class="bg-secondary rounded-pill text-white py-1 px-3" style="width: auto; height: auto;">' + data + '</label></div>';
                    //    }
                    //    else if (data == 'PostedJDE') {
                    //        return '<div class="text-start ps-2" style="width: 230px;"><label class="bg-info rounded-pill text-white py-1 px-3" style="width: auto; height: auto;">' + data + '</label></div>';
                    //    }
                    //    else {
                    //        return '<div class="text-start ps-2" style="width: 230px;"><label class="bg-primary rounded-pill text-white py-1 px-3" style="width: auto; height: auto;">' + data + '</label></div>';
                    //    }
                    //}
                },
                {
                    data: "approvedDateStr",
                    render: function (data) {
                        return '<label style="width: 170px;">' + data + '</label>';
                    }
                },
                {
                    data: "approverComment",
                    render: function (data) {
                        return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 500px;">' + data + '</label>';
                    }
                },
                {
                    data: "leaveStatus",
                    render: function (data) {
                        return '<label style="width: 150px;">' + data + '</label>';
                    }
                },
                {
                    data: "substituteFullName",
                    render: function (data) {
                        return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 300px;">' + data + '</label>';
                    }
                },
                {
                    data: "groupRountingSequence",
                    render: function (data) {
                        return '<label style="width: 200px;">' + data + '</label>';
                    }
                },
                {
                    data: "requisitionID"
                },
                {
                    data: "routingSequence"
                }
            ],
            columnDefs: [
                {
                    targets: "centeredColumn",
                    className: 'dt-body-center'
                },
                {
                    targets: 1,
                    render: function (data, type, row) {
                        return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 400px;">' + '<b>' + data + '</b>' + '<br>' + '<i>' + row.approverPosition + '</i>' + '</label>';
                    }
                },
                //{
                //    targets: 3,     // approvedDate
                //    render: function (data) {
                //        //var date = moment(data, ["DD-MM-YYYY", "MM-DD-YYYY", "YYYY-MM-DD"]);
                //        //if (date.isValid()) {
                //        //    return '<label style="width: 160px;">' + moment(data).format('DD-MMM-YYYY') + '</label>';
                //        //}
                //        //let dateInput = data as string;
                //        //if (!CheckIfNoValue(dateInput)) {
                //        //    return '<label style="width: 160px;">' + moment(dateInput).format('DD-MMM-YYYY') + '</label>';
                //        //}
                //        let dateInput = "";
                //        if (data != null)
                //            dateInput = ConvertToISODate(data) as string;
                //        //if (data !== null) {
                //            return '<label style="width: 160px;">' + moment(data).format('DD-MMM-YYYY') + '</label>';
                //        //}
                //    }
                //},
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
function populateWFStatusTable(data) {
    var dataset = data;
    if (dataset == "undefined" || dataset == null) {
        // Get DataTable API instance
        var table = $("#workflowTable").dataTable().api();
        table.clear().draw();
        HideLoadingPanel(gContainer);
    }
    else {
        let reportTitle = "Workflow Approval Status";
        // Save the table record count
        statusListCount = dataset.length;
        $("#workflowTable")
            .on('init.dt', function () {
            HideLoadingPanel(gContainer);
            if (statusListCount > 0)
                $('span[class~="recordCount"').html("Found <b>" + statusListCount.toString() + "</b> record(s).");
            else
                $('span[class~="recordCount"').text("No records found!");
            // Reset the buttons
            $('#btnSearch').removeAttr("disabled");
            $('span[class~="spinicon"]').attr("hidden", "hidden"); // Hide spin icon
            $('span[class~="normalicon"]').removeAttr("hidden"); // Show normal icon
        })
            .DataTable({
            data: dataset,
            processing: true,
            serverSide: false,
            orderMulti: false,
            destroy: true,
            scrollX: true,
            language: {
                emptyTable: "No records found in the database."
            },
            lengthMenu: [[5, 10, 20, 50, 100, -1], [5, 10, 20, 50, 100, "All"]],
            pageLength: 10,
            //order: [[7, 'asc'], [8, 'asc']],
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
                //{
                //    data: "approvalRole",
                //    render: function (data) {
                //        return '<label class="d-inline-block text-truncate ps-2 text-start text-primary fw-bold" style="width: 300px;">' + data + '</label>';
                //    }
                //},
                {
                    data: "approver"
                }
                //{
                //    data: "currentStatus",
                //    render: function (data) {
                //        return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 220px;">' + data + '</label>';
                //    }
                //},
                //{
                //    data: "approvedDateStr",
                //    render: function (data) {
                //        return '<label style="width: 170px;">' + data + '</label>';
                //    }
                //},
                //{
                //    data: "approverRemarks",
                //    render: function (data) {
                //        return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 500px;">' + data + '</label>';
                //    }
                //},
                //{
                //    data: "activityID"
                //},
                //{
                //    data: "activityCode"
                //},
                //{
                //    data: "activitySequence"
                //}
            ]
            //columnDefs: [
            //    {
            //        targets: "centeredColumn",
            //        className: 'dt-body-center'
            //    },
            //    {
            //        targets: 1,     // approver
            //        render: function (data, type, row) {
            //            return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 400px;">' + '<b>' + data + '</b>' + '<br>' + '<i>' + row.approverPosition + '</i>' + '</label>';
            //        }
            //    },
            //    {
            //        targets: "hiddenColumn",
            //        visible: false
            //    },
            //    {
            //        targets: "doNotOrder",
            //        orderable: false
            //    }
            //]
        });
    }
}
function displayErrorStatus(obj, errText, focusObj) {
    let alert = $(obj).find(".alert");
    if ($(alert).find(".errorText") != undefined)
        $(alert).find(".errorText").html(errText);
    if (obj != undefined)
        $(obj).removeAttr("hidden");
    $(alert).show();
    if (focusObj != undefined)
        $(focusObj).focus();
}
// #endregion
//#region Action Button Methods
function searchButtonStatus() {
    var hasError = false;
    // Hide all error alerts
    $('.errorPanel').attr("hidden", "hidden");
    HideErrorMessage();
    if (!hasError) {
        // Set the current container
        gContainer = $('.formWrapper');
        // Disable the search button
        $('#btnSearch').attr("disabled", "disabled");
        // Show/hide the spinner icon
        $('span[class~="spinicon"]').removeAttr("hidden");
        $('span[class~="normalicon"]').attr("hidden", "hidden");
        //if (isUseNewWF) {
        //    ShowLoadingPanel(gContainer, 2, 'Loading the workflow status, please wait...');
        //    loadWorkflowStatusTable();
        //}
        //else {
        ShowLoadingPanel(gContainer, 2, 'Loading requisition status, please wait...');
        loadStatusDataTable();
        //}
    }
}
function resetButtonStatus() {
    // Clear session objects
    DeleteDataFromSession("statusCriteria");
    resetStatusForm();
}
//#endregion
// #region Database Methods
function loadStatusDataTable() {
    var _a;
    try {
        const searchFilter = new StatusSearchCriteria();
        if (!CheckIfNoValue((_a = $("#hidRequisitionID").val()) === null || _a === void 0 ? void 0 : _a.toString()))
            searchFilter.requisitionID = GetIntValue($("#hidRequisitionID").val());
        // Save filter criteria to session storage
        let inquiryCriteria = GetDataFromSession("inquiryCriteria");
        if (CheckIfNoValue(inquiryCriteria))
            SaveDataToSession("inquiryCriteria", JSON.stringify(searchFilter));
        $.ajax({
            url: "/UserFunctions/Project/GetRequisitionStatusTable",
            type: "GET",
            dataType: "json",
            contentType: "application/json; charset=utf-8",
            cache: false,
            async: true,
            data: searchFilter,
            success: function (response, status) {
                if (status == "success") {
                    populateStatusTable(response.data);
                }
                else {
                    HideLoadingPanel(gContainer);
                    ShowErrorMessage("Unable to load requisition status records from the database, please contact ICT for technical support.");
                }
            },
            error: function (err) {
                HideLoadingPanel(gContainer);
                ShowErrorMessage("The following error has occured while executing loadStatusDataTable(): " + err.responseText);
            }
        });
    }
    catch (error) {
        HideLoadingPanel(gContainer);
        ShowErrorMessage("The following error has occured while fetching data from the database: " + "<b>" + error.message + "</b>");
    }
}
function loadWorkflowStatusTable() {
    var _a;
    try {
        const searchFilter = new StatusSearchCriteria();
        if (!CheckIfNoValue((_a = $("#hidCEANo").val()) === null || _a === void 0 ? void 0 : _a.toString()))
            searchFilter.ceaNo = GetStringValue($("#hidCEANo").val());
        // Save filter criteria to session storage
        let inquiryCriteria = GetDataFromSession("inquiryCriteria");
        if (CheckIfNoValue(inquiryCriteria))
            SaveDataToSession("inquiryCriteria", JSON.stringify(searchFilter));
        $.ajax({
            url: "/UserFunctions/Project/GetWorkflowStatusTable",
            type: "GET",
            dataType: "json",
            contentType: "application/json; charset=utf-8",
            cache: false,
            async: true,
            data: searchFilter,
            success: function (response, status) {
                if (status == "success") {
                    populateWFStatusTable(response.data);
                }
                else {
                    HideLoadingPanel(gContainer);
                    ShowErrorMessage("Unable to load requisition status records from the database, please contact ICT for technical support.");
                }
            },
            error: function (err) {
                HideLoadingPanel(gContainer);
                ShowErrorMessage("The following error has occured while executing loadWorkflowStatusTable(): " + err.responseText);
            }
        });
    }
    catch (error) {
        HideLoadingPanel(gContainer);
        ShowErrorMessage("The following error has occured while fetching data from the database: " + "<b>" + error.message + "</b>");
    }
}
// #endregion
//# sourceMappingURL=requisitionStatus.js.map