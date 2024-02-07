// #region Classes
class SearchCriterias {
    constructor() {
        this.projectNo = "";
        this.requisitionNo = "";
        this.expenditureType = "";
        this.fiscalYear = 0;
        this.statusCode = "";
        this.costCenter = "";
        this.empNo = 0;
        this.approvalType = "";
        this.filterToUser = false;
        this.keyWords = "";
        this.startDate = "";
        this.endDate = "";
        this.otherEmpNo = 0;
        this.createdByType = 0;
    }
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
    resetInquiryForm();
    // Show toast message if necessary
    if (!CheckIfNoValue($("input[name='ToastNotification']").val())) {
        ShowToastMessage(toastTypes.success, $("input[name='ToastNotification']").val(), "Success Notification");
        // Clear the notification
        $("input[name='ToastNotification']").val("");
    }
    // #region Initialize controls
    $('input[name="StartDate"]').datepicker({
        dateFormat: "dd/mm/yy",
        altField: "#hdnReqStartDate",
        altFormat: "yy-mm-dd",
        duration: "slow",
        prevText: "Click for previous months",
        nextText: "Click for next months",
        showOtherMonths: true,
        selectOtherMonths: true,
        changeMonth: true,
        changeYear: true,
        numberOfMonths: [1, 1],
        showWeek: false,
        showAnim: "slideDown"
    });
    $('input[name="EndDate"]').datepicker({
        dateFormat: "dd/mm/yy",
        altField: "#hdnReqEndDate",
        altFormat: "yy-mm-dd",
        duration: "slow",
        prevText: "Click for previous months",
        nextText: "Click for next months",
        showOtherMonths: true,
        selectOtherMonths: true,
        changeMonth: true,
        changeYear: true,
        numberOfMonths: [1, 1],
        showWeek: false,
        showAnim: "slideDown"
    });
    $("input:required").on({
        focus: function () {
            $(this).css("border", "2px solid red");
            $(this).css("border-radius", "5px");
        },
        blur: function () {
            $(this).css("border", $("input:optional").css("border"));
            $(this).css("border-radius", $("input:optional").css("border"));
        }
    });
    // #endregion
    // #region Initialize event handlers
    $("#approvalSwitch").click(function () {
        if ($(this).is(":checked")) {
            $('select[name="ApprovalType"]').removeAttr("disabled");
            $('select[name="ApprovalType"]').val("ASGNTOME");
            // Reset search criteria
            //$("#cboFiscalYear").val("");
            $('input[name="ProjectNo"]').val("");
            $('input[name="RequisitionNo"]').val("");
            $('select[name="CostCenter"').val("");
            $('select[name="ExpenditureType"').val("");
            $('select[name="Status"').val("");
            $('input[name="Keywords"]').val("");
            $('input[name="StartDate"]').val("");
            $('input[name="EndDate"]').val("");
            // Reset dataTable
            populateInquiryTable(null);
            // Invoke search button
            $("#btnSearch").click();
        }
        else {
            $('select[name="ApprovalType"]').attr("disabled", "disabled");
            $('select[name="ApprovalType"]').val("");
            // Reset and hide employee number search box
            $("#txtOtherEmpNo").val("");
            /*$("#txtOtherEmpNo").attr("hidden", "hidden");*/
            $('div[class~="groupAssignPerson"').attr("hidden", "hidden");
            // Reset the search criteria controls and then invoke the Search button
            $("#btnHiddenReset").click();
            $("#btnSearch").click();
            // Reset dataTable
            //populateInquiryTable(null);
        }
    });
    $('select[name="ApprovalType"]').change(function () {
        let value = $(this).val();
        if (value == "ASGNTOOTHR") {
            // Show the Assignee Employee box
            //$("#txtOtherEmpNo").removeAttr("hidden");
            $('div[class~="groupAssignPerson"').removeAttr("hidden");
            $("#txtOtherEmpNo").val("");
            $("#txtOtherEmpNo").focus();
        }
        else {
            // Hide the Assignee Employee box
            /*$("#txtOtherEmpNo").attr("hidden", "hidden");*/
            $('div[class~="groupAssignPerson"').attr("hidden", "hidden");
        }
    });
    $("#btnFindEmp").on('click', openEmployeeLookup);
    // #endregion
    // #region Initialize form secuity
    let userName = GetStringValue($("#hidUserName").val());
    let formCode = GetStringValue($("#hidFormCode").val());
    // Check first if user credentials was already been initialize
    let userCredential = GetDataFromSession("UserCredential");
    if (!CheckIfNoValue(userCredential)) {
        const model = JSON.parse(userCredential);
        // Get user access information
        GetUserFormAccess(formCode, model.costCenter, model.empNo, PageNameList.RequisitionInquiry);
    }
    else {
        GetUserCredential(userName, formCode, PageNameList.ProjectInquiry);
    }
    // #endregion
    // #region Check if there was saved search criteria
    // Check if need to invoke the Search button
    let ignoreSavedData = Boolean($("input[name='IgnoreSavedData']").val());
    let savedData = GetDataFromSession("inquiryCriteria");
    if (!CheckIfNoValue(savedData) && !ignoreSavedData) {
        const data = JSON.parse(savedData);
        // Bind data to controls
        $('input[name="ProjectNo"]').val(data.projectNo);
        $('input[name="RequisitionNo"]').val(data.requisitionNo);
        $('select[name="ExpenditureType"').val(data.expenditureType);
        $('select[name="FiscalYear"').val(data.fiscalYear);
        $('select[name="Status"').val(data.statusCode);
        $('select[name="CostCenter"').val(data.costCenter);
        $('input[name="Keywords"]').val(data.keywords);
        $('input[name="StartDate"]').val(data.startDate);
        $('input[name="EndDate"]').val(data.endDate);
        $('select[name="ApprovalType"]').val(data.approvalType);
        $("#hidEmpNo").val(data.empNo);
        $("#hidOtherEmpNo").val(data.otherEmpNo);
        switch (data.createdByType) {
            case 0: // All
                $("#createdByAll").prop("checked", true);
                $("#createdByMe").prop("checked", false);
                $("#createdByOthers").prop("checked", false);
                break;
            case 2: // Other
                $("#createdByAll").prop("checked", false);
                $("#createdByMe").prop("checked", false);
                $("#createdByOthers").prop("checked", true);
                break;
            default:
                $("#createdByAll").prop("checked", false);
                $("#createdByMe").prop("checked", true);
                $("#createdByOthers").prop("checked", false);
                break;
        }
        if (data.filterToUser) {
            $('#approvalSwitch').prop("checked", true);
            $('div[class~="groupAssignPerson"').removeAttr("hidden");
            // Get the selected employee
            let searchedEmpNo = $("#hidSearchEmpNo").val();
            if (!CheckIfNoValue(searchedEmpNo)) {
                $("#hidOtherEmpNo").val(searchedEmpNo);
                $("#txtOtherEmpNo").val(searchedEmpNo);
            }
            else {
                $("#txtOtherEmpNo").val(data.otherEmpNo);
                $("#hidOtherEmpNo").val(data.otherEmpNo);
            }
            // Enable the approval type combobox
            $('select[name="ApprovalType"]').prop("disabled", false);
            if ($('select[name="ApprovalType"]').val() == "ASGNTOOTHR") {
                // Show the Assignee Employee box
                $('div[class~="groupAssignPerson"').removeAttr("hidden");
            }
            else {
                // Hide the Assignee Employee box
                $('div[class~="groupAssignPerson"').attr("hidden", "hidden");
            }
        }
        else {
            $('#approvalSwitch').prop("checked", false);
            $('div[class~="groupAssignPerson"').attr("hidden", "hidden");
        }
    }
    //else {
    //    // Check if need to invoke the Search button
    //    let invokeSearch: boolean = Boolean($("input[name='InvokeSearch']").val());
    //    if (invokeSearch)
    //        searchButtonInquiry();
    //}
    // #endregion
    // Invoke the search button
    searchButtonInquiry();
    // Get employees
    getEmployeeList();
});
// #endregion
// #region Private Methods
function resetInquiryForm() {
    HideErrorMessage();
    // Hide all error alerts
    $('.errorPanel').attr("hidden", "hidden");
    // Reset dataTable
    populateInquiryTable(null);
    // #region Reset Filter Pending Approval controls
    $('select[name="ApprovalType"]').attr("disabled", "disabled");
    $('select[name="ApprovalType"]').val("");
    $('select[name="Status"]').val("");
    $('select[name="CostCenter"]').val("");
    // Reset and hide employee number search box
    $("#txtOtherEmpNo").val("");
    $('div[class~="groupAssignPerson"').attr("hidden", "hidden");
    // #endregion
    // Reset the buttons
    $('#btnSearch').removeAttr("disabled");
    $('span[class~="spinicon"]').attr("hidden", "hidden"); // Hide spin icon
    $('span[class~="normalicon"]').removeAttr("hidden"); // Show normal icon
    // Move to the top of the page
    window.scrollTo(0, 0);
    $("#btnHiddenReset").click();
}
function populateEmployeeList(data) {
    try {
        if (CheckIfNoValue(data))
            return;
        const empArray = [];
        var item;
        for (var i = 0; i < data.length - 1; i++) {
            item = data[i];
            let empItem = {
                label: item.empNo + " - " + item.empName,
                value: item.empNo,
            };
            // Add object to array
            empArray.push(empItem);
        }
        $("#txtOtherEmpNo").autocomplete({
            source: empArray,
            autoFocus: true,
            minLength: 2,
            delay: 300,
            select: function (event, ui) {
                if (ui.item != null && ui.item != undefined) {
                    // Save the employee details to the hidden fields
                    $("#hidOtherEmpNo").val(ui.item.value);
                    // Get the employee name
                    if (ui.item.label.length > 0) {
                        var empArray = ui.item.label.trim().split("-");
                        if (empArray != undefined) {
                            //if (empArray.length == 1) {
                            $("#txtOtherEmpNo").val(empArray[0].trim());
                            //}
                            //else {
                            //    $("#txtOtherEmpNo").val(empArray[1].trim());
                            //}
                        }
                    }
                    // Hide missing approver error alert
                    $("#otherEmpValid").attr("hidden", "hidden");
                    return false;
                }
            },
            change: function (event, ui) {
                if (ui.item == undefined || ui.item == null) {
                    $("#hidOtherEmpNo").val("");
                    displayErrorInquiry($('#otherEmpValid'), "The specified employee does not exist.", $('#txtOtherEmpNo'));
                    $("#txtOtherEmpNo").focus();
                }
                else
                    $('#otherEmpValid').attr("hidden", "hidden");
                return false;
            }
        });
        $("#txtOtherEmpNo").autocomplete("enable");
    }
    catch (error) {
        HideLoadingPanel(gContainer);
        ShowErrorMessage("The following error has occured executing the populateEmployeeList() function: " + "<b>" + error.message + "</b>");
    }
}
function populateInquiryTable(data) {
    var dataset = data;
    if (dataset == "undefined" || dataset == null) {
        // Get DataTable API instance
        var table = $("#requisitionTable").dataTable().api();
        table.clear().draw();
        HideLoadingPanel(gContainer);
    }
    else {
        let reportTitle = "Requisitions Summary Report";
        $("#requisitionTable")
            .on('init.dt', function () {
            HideLoadingPanel(gContainer);
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
            order: [[1, 'desc']],
            drawCallback: function () {
                $('.lnkProjectNo').on('click', openProjectDetail);
                $('.lnkReqNo').on('click', openRequisitionDetail);
                $('.lnkStatus').on('click', openRequisitionStatus);
                $('.lnkViewExpense').on('click', openExpenseDetail);
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
                    data: "projectNo"
                },
                {
                    data: "requisitionNo"
                },
                //{
                //    data: "workflowStatus"
                //},
                {
                    data: "ceaStatusDesc",
                },
                {
                    data: "currentlyAssignedTo",
                    render: function (data) {
                        return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 300px;">' + data + '</label>';
                    }
                },
                {
                    data: "requisitionDate",
                    render: function (data) {
                        return '<label style="width: 150px;">' + moment(data).format('DD-MMM-YYYY') + '</label>';
                    }
                },
                {
                    data: "description",
                    /*render: $.fn.dataTable.render.text()*/
                    render: function (data) {
                        return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 500px;">' + data + '</label>';
                    }
                },
                {
                    data: "dateofComission",
                    render: function (data) {
                        return '<label style="width: 160px;">' + moment(data).format('DD-MMM-YYYY') + '</label>';
                    }
                },
                {
                    data: "amount",
                    render: $.fn.dataTable.render.number(',', '.', 3)
                },
                {
                    data: "fiscalYear",
                    render: function (data) {
                        return '<label style="width: 120px;">' + data + '</label>';
                    }
                },
                {
                    data: "costCenter",
                    render: function (data) {
                        return '<label style="width: 130px;">' + data + '</label>';
                    }
                },
                {
                    data: "createDate",
                    render: function (data) {
                        return '<label style="width: 150px;">' + moment(data).format('DD-MMM-YYYY') + '</label>';
                    }
                },
                {
                    data: "createdByName",
                    render: function (data) {
                        return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 300px;">' + data + '</label>';
                    }
                },
                {
                    data: null
                },
                {
                    data: "requisitionID"
                },
                {
                    data: "assignedToEmpNo"
                },
                {
                    data: "useNewWF"
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
                        return '<label style="width: 130px;">' + '<a href="javascript:void(0)" class="lnkProjectNo gridLink" style="font-size: 14px;" data-projectno=' + row.projectNo + '> ' + row.projectNo + '</a>' + '</label>';
                    }
                },
                {
                    targets: 1,
                    render: function (data, type, row) {
                        return '<label style="width: 130px;">' + '<a href="javascript:void(0)" class="lnkReqNo gridLink" style="color: red; font-size: 14px;" data-requisitionno=' + row.requisitionNo + ' data-assignedtoempno=' + row.assignedToEmpNo + '> ' + row.requisitionNo + '</a>' + '</label>';
                    }
                },
                {
                    targets: 2,
                    render: function (data, type, row) {
                        if (row.ceaStatusCode == 'Submitted' || row.ceaStatusCode == 'AwaitingChairmanApproval') {
                            return '<a class="btn btn-sm btn-primary rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + ' data-usenewwf=' + row.useNewWFString + '> ' + row.ceaStatusDesc + '</a>';
                        }
                        else if (row.ceaStatusCode == 'Approved') {
                            return '<a class="btn btn-sm btn-success rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + ' data-usenewwf=' + row.useNewWFString + '> ' + row.ceaStatusDesc + '</a>';
                        }
                        else if (row.ceaStatusCode == 'UploadedToOneWorld') {
                            return '<a class="btn btn-sm btn-success rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + ' data-usenewwf=' + row.useNewWFString + '> ' + row.ceaStatusDesc + '</a>';
                        }
                        else if (row.ceaStatusCode == 'Cancelled') {
                            return '<a class="btn btn-sm btn-warning rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + ' data-usenewwf=' + row.useNewWFString + '> ' + row.ceaStatusDesc + '</a>';
                        }
                        else if (row.ceaStatusCode == 'Rejected') {
                            return '<a class="btn btn-sm btn-danger rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + ' data-usenewwf=' + row.useNewWFString + '> ' + row.ceaStatusDesc + '</a>';
                        }
                        else if (row.ceaStatusCode == 'Closed') {
                            return '<a class="btn btn-sm btn-secondary rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + ' data-usenewwf=' + row.useNewWFString + '> ' + row.ceaStatusDesc + '</a>';
                        }
                        else if (row.ceaStatusCode == 'Draft') {
                            return '<a class="btn btn-sm btn-info rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + ' data-usenewwf=' + row.useNewWFString + '> ' + row.ceaStatusDesc + '</a>';
                        }
                        else {
                            return '<a class="btn btn-sm btn-info rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + ' data-usenewwf=' + row.useNewWFString + '> ' + row.ceaStatusDesc + '</a>';
                        }
                    }
                    //render: function (data, type, row) {
                    //    if (row.statusHandlingCode == 'Open') {
                    //        return '<a class="btn btn-sm btn-primary rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + ' data-usenewwf=' + row.useNewWFString + '> ' + row.workflowStatus + '</a>';
                    //    }
                    //    else if (row.statusHandlingCode == 'Cancelled') {
                    //        return '<a class="btn btn-sm btn-warning rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + ' data-usenewwf=' + row.useNewWFString + '> ' + row.workflowStatus + '</a>';
                    //    }
                    //    else if (row.statusHandlingCode == 'Rejected') {
                    //        return '<a class="btn btn-sm btn-danger rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + ' data-usenewwf=' + row.useNewWFString + '> ' + row.workflowStatus + '</a>';
                    //    }
                    //    else if (row.statusHandlingCode == 'Closed' || row.statusHandlingCode == 'Approved') {
                    //        return '<a class="btn btn-sm btn-secondary rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + ' data-usenewwf=' + row.useNewWFString + '> ' + row.workflowStatus + '</a>';
                    //    }
                    //    else if (row.statusHandlingCode == 'Draft') {
                    //        return '<a class="btn btn-sm btn-info rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + ' data-usenewwf=' + row.useNewWFString + '> ' + row.workflowStatus + '</a>';
                    //    }
                    //    else {
                    //        return '<a class="btn btn-sm btn-info rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + ' data-usenewwf=' + row.useNewWFString + '> ' + row.workflowStatus + '</a>';
                    //    }
                    //}
                },
                {
                    targets: 12,
                    render: function (data, type, row) {
                        return '<label style="width: 175px; font-size: 12px;">' + '<a class="btn btn-sm btn-danger text-white my-1 rounded-pill w-100 gridLink lnkViewExpense" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + '> ' +
                            '<span> <i class="fas fa-eye fa-1x fa-fw" > </i></span >' + "&nbsp;" +
                            "View Expenses" + '</a>' + '</label>';
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
            //order: []
        });
    }
}
function openProjectDetail() {
    let projectNo = $(this).text().trim();
    ShowLoadingPanel(gContainer, 1, 'Loading project details, please wait...');
    // Open the Project Details View
    location.href = "/UserFunctions/Project/ProjectDetail?projectNo=".concat(projectNo).concat("&callerForm=RequisitionInquiry");
}
function openRequisitionDetail() {
    let reqNo = $(this).text().trim();
    let actionType = 0;
    let assignedToEmpNo = GetIntValue($(this).attr("data-assignedtoempno"));
    let currentUserEmpNo = GetIntValue($("#hidEmpNo").val().toString());
    if ($('#approvalSwitch').is(":checked")) {
        if (assignedToEmpNo > 0 && currentUserEmpNo > 0 && assignedToEmpNo == currentUserEmpNo)
            actionType = 3; // Open for approval
    }
    ShowLoadingPanel(gContainer, 1, 'Loading requisition details, please wait...');
    // Open the Project Details View
    location.href = "/UserFunctions/Project/CEARequisition?requisitionNo=".concat(reqNo).concat("&actionType=").concat(actionType.toString()).concat("&callerForm=RequisitionInquiry");
}
function openRequisitionStatus() {
    let requisitionID = "";
    let projectNo = "";
    let requisitionNo = "";
    let createdNo = "";
    let createdName = "";
    let submittedDate = "";
    let useNewWF = "";
    if (!CheckIfNoValue($(this).attr("data-requisitionid")))
        requisitionID = $(this).attr("data-requisitionid");
    if (!CheckIfNoValue($(this).attr("data-projectno")))
        projectNo = $(this).attr("data-projectno");
    if (!CheckIfNoValue($(this).attr("data-requisitionno")))
        requisitionNo = $(this).attr("data-requisitionno");
    if (!CheckIfNoValue($(this).attr("data-createdno")))
        createdNo = $(this).attr("data-createdno");
    if (!CheckIfNoValue($(this).attr("data-createdname")))
        createdName = $(this).attr("data-createdname");
    if (!CheckIfNoValue($(this).attr("data-submitteddate")))
        submittedDate = $(this).attr("data-submitteddate");
    if (GetBooleanValue($(this).attr("data-usenewwf"))) {
        useNewWF = "true";
    }
    ShowLoadingPanel(gContainer, 1, 'Loading requisition status, please wait...');
    // Open the Requisition Status View
    //location.href = "/UserFunctions/Project/RequisitionStatusView?requisitionID=".concat(requisitionID).concat("&projectNo=").concat(projectNo).concat("&requisitionNo=")
    //    .concat(requisitionNo).concat("&createdNo=").concat(createdNo).concat("&createdName=").concat(createdName).concat("&submittedDate=").concat(submittedDate);
    location.href = "/UserFunctions/Project/RequisitionStatusView?requisitionID=".concat(requisitionID).concat("&projectNo=").concat(projectNo).concat("&requisitionNo=")
        .concat(requisitionNo).concat("&createdNo=").concat(createdNo).concat("&createdName=").concat(createdName).concat("&submittedDate=").concat(submittedDate).concat("&useNewWF=").concat(useNewWF);
}
function openExpenseDetail() {
    let requisitionID = "";
    let projectNo = "";
    let requisitionNo = "";
    if (!CheckIfNoValue($(this).attr("data-requisitionid")))
        requisitionID = $(this).attr("data-requisitionid");
    if (!CheckIfNoValue($(this).attr("data-projectno")))
        projectNo = $(this).attr("data-projectno");
    if (!CheckIfNoValue($(this).attr("data-requisitionno")))
        requisitionNo = $(this).attr("data-requisitionno");
    ShowLoadingPanel(gContainer, 1, 'Loading expense details, please wait...');
    // Open the Requisition Status View
    location.href = "/UserFunctions/Project/ExpensesView?requisitionID=".concat(requisitionID).concat("&projectNo=").concat(projectNo).concat("&requisitionNo=").concat(requisitionNo);
}
function openEmployeeLookup() {
    var _a, _b, _c, _d;
    ShowLoadingPanel(gContainer, 1, 'Loading Employee Lookup page, please wait...');
    // Delete existing search criteria data in the session
    let inquiryCriteria = GetDataFromSession("inquiryCriteria");
    if (!CheckIfNoValue(inquiryCriteria))
        DeleteDataFromSession("inquiryCriteria");
    // #region Save search criteria data into the session
    const searchFilter = new SearchCriterias();
    if (!CheckIfNoValue($('input[name="ProjectNo"]').val()))
        searchFilter.projectNo = $('input[name="ProjectNo"]').val().toString();
    if (!CheckIfNoValue($('input[name="RequisitionNo"]').val()))
        searchFilter.requisitionNo = $('input[name="RequisitionNo"]').val().toString();
    if (!CheckIfNoValue($('select[name="ExpenditureType"').val()))
        searchFilter.expenditureType = $('select[name="ExpenditureType"').val().toString();
    if (!CheckIfNoValue($('select[name="FiscalYear"').val()))
        searchFilter.fiscalYear = GetIntValue($('select[name="FiscalYear"').val().toString());
    if (!CheckIfNoValue($('select[name="Status"').val()))
        searchFilter.statusCode = $('select[name="Status"').val().toString();
    if (!CheckIfNoValue($('select[name="CostCenter"').val()))
        searchFilter.costCenter = $('select[name="CostCenter"').val().toString();
    if (!CheckIfNoValue($('input[name="Keywords"]').val()))
        searchFilter.keyWords = $('input[name="Keywords"]').val().toString();
    if (!CheckIfNoValue((_a = $('input[name="StartDate"]').val()) === null || _a === void 0 ? void 0 : _a.toString()))
        searchFilter.startDate = ConvertToISODate($('input[name="StartDate"]').val().toString());
    if (!CheckIfNoValue((_b = $('input[name="EndDate"]').val()) === null || _b === void 0 ? void 0 : _b.toString()))
        searchFilter.endDate = ConvertToISODate($('input[name="EndDate"]').val().toString());
    if (!CheckIfNoValue($('select[name="ApprovalType"').val()))
        searchFilter.approvalType = $('select[name="ApprovalType"').val().toString();
    if (!CheckIfNoValue((_c = $("#hidEmpNo").val()) === null || _c === void 0 ? void 0 : _c.toString()))
        searchFilter.empNo = GetIntValue($("#hidEmpNo").val().toString());
    if (!CheckIfNoValue((_d = $("#hidOtherEmpNo").val()) === null || _d === void 0 ? void 0 : _d.toString()))
        searchFilter.otherEmpNo = GetIntValue($("#hidOtherEmpNo").val().toString());
    if (!CheckIfNoValue($('#approvalSwitch').val()))
        searchFilter.statusCode = $('#approvalSwitch').val().toString();
    if ($('#approvalSwitch').is(":checked"))
        searchFilter.filterToUser = true;
    else
        searchFilter.filterToUser = false;
    var selectedOption = $("#createdByDiv input[type='radio']:checked");
    if (selectedOption.length > 0) {
        searchFilter.createdByType = GetIntValue(selectedOption.val());
    }
    SaveDataToSession("inquiryCriteria", JSON.stringify(searchFilter));
    // #endregion
    // Open the Project Details View
    location.href = "/UserFunctions/Project/EmployeeLookupView?callerForm=RequisitionInquiry";
}
function onlyNumberKeyInq(evt) {
    // Only ASCII character in that range allowed
    var ASCIICode = (evt.which) ? evt.which : evt.keyCode;
    if (ASCIICode > 31 && (ASCIICode < 48 || ASCIICode > 57))
        return false;
    return true;
}
function displayErrorInquiry(obj, errText, focusObj) {
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
function searchButtonInquiry() {
    var _a, _b;
    var hasError = false;
    // Hide all error alerts
    $('.errorPanel').attr("hidden", "hidden");
    HideErrorMessage();
    // #region Validate data input
    //Check if Requisition Date range is valid
    let startDate = (_a = $('input[name="StartDate"]').val()) === null || _a === void 0 ? void 0 : _a.toString();
    let endDate = (_b = $('input[name="EndDate"]').val()) === null || _b === void 0 ? void 0 : _b.toString();
    if (!CheckIfNoValue(startDate) || !CheckIfNoValue(endDate)) {
        if (CheckIfNoValue(startDate) && !CheckIfNoValue(endDate)) {
            displayErrorInquiry($('#durationValid'), "Must specify the start date.", $('input[name="StartDate"'));
            hasError = true;
        }
        else if (!CheckIfNoValue(startDate) && CheckIfNoValue(endDate)) {
            displayErrorInquiry($('#durationValid'), "Must specify the end date.", $('input[name="EndDate"'));
            hasError = true;
        }
        else {
            if (IsValidDate(startDate) == false) {
                displayErrorInquiry($('#durationValid'), "Start date is invalid!", $('input[name="StartDate"'));
                hasError = true;
            }
            else if (IsValidDate(endDate) == false) {
                displayErrorInquiry($('#durationValid'), "End date is invalid!", $('input[name="EndDate"'));
                hasError = true;
            }
            else {
                if ($('#durationValid').attr("hidden") == undefined)
                    $('#durationValid').attr("hidden", "hidden");
            }
        }
    }
    if (GetBooleanValue($('#approvalSwitch').val())) {
        // Check Searched Employee
        if (CheckIfNoValue($('input[name="OtherEmpNo"').val()) &&
            $('select[name="ApprovalType"]').val() == "ASGNTOOTHR") {
            displayErrorInquiry($('#otherEmpValid'), "Please specify the employee.", $('input[name="OtherEmpNo"'));
            hasError = true;
        }
        else {
            if ($('#otherEmpValid').attr("hidden") == undefined)
                $('#otherEmpValid').attr("hidden", "hidden");
        }
    }
    // #endregion
    if (!hasError) {
        // Set the current container
        gContainer = $('.gridWrapper');
        // Disable the search button
        $('#btnSearch').attr("disabled", "disabled");
        // Show/hide the spinner icon
        $('span[class~="spinicon"]').removeAttr("hidden");
        $('span[class~="normalicon"]').attr("hidden", "hidden");
        // Clear session
        DeleteDataFromSession("inquiryCriteria");
        ShowLoadingPanel(gContainer, 2, 'Loading requisition data, please wait...');
        loadInquiryDataTable();
    }
}
function resetButtonInquiry() {
    // Set the current container
    gContainer = $('.formWrapper');
    HideErrorMessage();
    ShowLoadingPanel(gContainer, 2, 'Clearing the form, please wait...');
    // Clear session objects
    DeleteDataFromSession("inquiryCriteria");
    resetInquiryForm();
}
//#endregion
// #region Database Methods
function loadInquiryDataTable() {
    var _a, _b, _c, _d;
    try {
        const searchFilter = new SearchCriterias();
        if (!CheckIfNoValue($('input[name="ProjectNo"]').val()))
            searchFilter.projectNo = $('input[name="ProjectNo"]').val().toString();
        if (!CheckIfNoValue($('input[name="RequisitionNo"]').val()))
            searchFilter.requisitionNo = $('input[name="RequisitionNo"]').val().toString();
        if (!CheckIfNoValue($('select[name="ExpenditureType"').val()))
            searchFilter.expenditureType = $('select[name="ExpenditureType"').val().toString();
        if (!CheckIfNoValue($('select[name="FiscalYear"').val()))
            searchFilter.fiscalYear = GetIntValue($('select[name="FiscalYear"').val().toString());
        if (!CheckIfNoValue($('select[name="Status"').val()))
            searchFilter.statusCode = $('select[name="Status"').val().toString();
        if (!CheckIfNoValue($('select[name="CostCenter"').val()))
            searchFilter.costCenter = $('select[name="CostCenter"').val().toString();
        if (!CheckIfNoValue($('input[name="Keywords"]').val()))
            searchFilter.keyWords = $('input[name="Keywords"]').val().toString();
        if (!CheckIfNoValue((_a = $('input[name="StartDate"]').val()) === null || _a === void 0 ? void 0 : _a.toString()))
            searchFilter.startDate = ConvertToISODate($('input[name="StartDate"]').val().toString());
        if (!CheckIfNoValue((_b = $('input[name="EndDate"]').val()) === null || _b === void 0 ? void 0 : _b.toString()))
            searchFilter.endDate = ConvertToISODate($('input[name="EndDate"]').val().toString());
        if (!CheckIfNoValue($('select[name="ApprovalType"').val()))
            searchFilter.approvalType = $('select[name="ApprovalType"').val().toString();
        if (!CheckIfNoValue((_c = $("#hidEmpNo").val()) === null || _c === void 0 ? void 0 : _c.toString()))
            searchFilter.empNo = GetIntValue($("#hidEmpNo").val().toString());
        if (!CheckIfNoValue((_d = $("#hidOtherEmpNo").val()) === null || _d === void 0 ? void 0 : _d.toString()))
            searchFilter.otherEmpNo = GetIntValue($("#hidOtherEmpNo").val().toString());
        if ($('#approvalSwitch').is(":checked"))
            searchFilter.filterToUser = true;
        else
            searchFilter.filterToUser = false;
        var selectedOption = $("#createdByDiv input[type='radio']:checked");
        if (selectedOption.length > 0) {
            searchFilter.createdByType = GetIntValue(selectedOption.val());
        }
        // #region Save filter criteria to session storage
        let inquiryCriteria = GetDataFromSession("inquiryCriteria");
        if (!CheckIfNoValue(inquiryCriteria)) {
            // Delete existing data
            DeleteDataFromSession("inquiryCriteria");
        }
        SaveDataToSession("inquiryCriteria", JSON.stringify(searchFilter));
        // #endregion
        $.ajax({
            url: "/UserFunctions/Project/LoadRequisitionList",
            type: "GET",
            dataType: "json",
            contentType: "application/json; charset=utf-8",
            cache: false,
            async: true,
            data: searchFilter,
            success: function (response, status) {
                if (status == "success") {
                    populateInquiryTable(response.data);
                    if (CheckIfNoValue(response.data)) {
                        // Reset the buttons
                        $('#btnSearch').removeAttr("disabled");
                        $('span[class~="spinicon"]').attr("hidden", "hidden"); // Hide spin icon
                        $('span[class~="normalicon"]').removeAttr("hidden"); // Show normal icon
                        //ShowToastMessage(toastTypes.error, "Sorry, no data found for the specified search criteria.", "Notification");
                    }
                }
                else {
                    HideLoadingPanel(gContainer);
                    ShowErrorMessage("Unable to load requisition records from the database, please contact ICT for technical support.");
                }
            },
            error: function (err) {
                HideLoadingPanel(gContainer);
                ShowErrorMessage("The following error has occured while executing loadInquiryDataTable(): " + err.responseText);
            }
        });
    }
    catch (error) {
        HideLoadingPanel(gContainer);
        ShowErrorMessage("The following error has occured while loading the data to the search results table: " + "<b>" + error.message + "</b>");
    }
}
function getEmployeeList() {
    const searchFilter = new SearchCriterias();
    searchFilter.empNo = 0;
    $.ajax({
        url: "/UserFunctions/Project/GetEmployeeList",
        type: "GET",
        dataType: "json",
        contentType: "application/json; charset=utf-8",
        cache: false,
        async: true,
        data: searchFilter,
        success: function (response, status) {
            if (status == "success") {
                populateEmployeeList(response.data);
            }
            else {
                throw new Error("Something went wrong while fethcing data data from the database!");
            }
        },
        error: function (err) {
            throw err;
        }
    });
}
// #endregion
//# sourceMappingURL=requisitionInquiry.js.map