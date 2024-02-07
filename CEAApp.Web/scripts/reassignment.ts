// #region Classes
 class SearchCriterias2 {
    projectNo: string;
    requisitionNo: string;
    expenditureType: string;
    fiscalYear: number;
    statusCode: string;
    costCenter: number;
    empNo: number;
    approvalType: string;
    filterToUser: boolean;
    keyWords: string;
    startDate: string;
    endDate: string;
    otherEmpNo: number;
    fromFiscalYear: number;
     toFiscalYear: number;
     currentAssignEmp: number;
     newAssignEmp: number;

    constructor() {
        this.projectNo = "";
        this.requisitionNo = "";
        this.expenditureType = "";
        this.fiscalYear = 0;
        this.statusCode = "";
        this.costCenter = 0;
        this.empNo = 0;
        this.approvalType = ""
        this.filterToUser = false;
        this.keyWords = "";
        this.startDate = "";
        this.endDate = "";
        this.otherEmpNo = 0;
        this.fromFiscalYear = 0;
        this.toFiscalYear = 0;
        this.currentAssignEmp = 0;
        this.newAssignEmp = 0;
    }
}

// #endregion

var container;

$(() => {
    gContainer = $('.formWrapper');

    ShowLoadingPanel(container, 2, 'Loading data...');

    const button = document.getElementById('btnSearch');

    button?.addEventListener('click', function handleClick(event) {

        // Show/hide the spinner icon
        $('span[class~="spinicon"]').removeAttr("hidden");
        $('span[class~="normalicon"]').attr("hidden", "hidden");

        container = $('.gridWrapper');
        ShowLoadingPanel(container, 2, 'Loading data...');
        //LoadReassignmentDataTable();
        searchRequisition();
        // Hide all tool tips
        $('[data-bs-toggle="tooltip"]').tooltip('hide');
    });

    $("#ReassignTable")
        .on('init.dt', function () {    // This event will fire after loading the data in the table
            HideLoadingPanel(gContainer);
        })
        .DataTable({
            "language": {
                "emptyTable": "No data available"
            }
        });

    // #region Initialize form secuity
    let userName = GetStringValue($("#hidUserName").val());
    let formCode = GetStringValue($("#hidFormCode").val());

    // Check first if user credentials was already been initialize
    let userCredential = GetDataFromSession("UserCredential");
    if (!CheckIfNoValue(userCredential)) {
        const model = JSON.parse(userCredential!);
        // Get user access information
        GetUserFormAccess(formCode, model.costCenter, model.empNo, PageNameList.RequestAdmin);
        $("#hidUserId").val(model.empNo);
    }
    else {
        GetUserCredential(userName, formCode, PageNameList.RequestAdmin);
    }
    // #endregion

    // Get employees
    getAllEmployeeList();

    $("#btnReset").on('click', handleReAssignResetButtonClick);
});

var table;

function PopulateReassignmentDataTable(data: any) {
 
    gContainer = $('.gridWrapper');
    var dataset = data;
    if (data == null || data === undefined) {
        // Get DataTable API instance
        table = $("#ReassignTable").dataTable().api();
        table.clear().draw();
        HideLoadingPanel(gContainer);

        $('#btnSearch').removeAttr("disabled");
        $('span[class~="spinicon"]').attr("hidden", "hidden");      // Hide spin icon
        $('span[class~="normalicon"]').removeAttr("hidden");        // Show normal icon
        return;
    }

    if (dataset == "undefined" || dataset == null) {
        // Get DataTable API instance
        table = $("#ReassignTable").dataTable().api();
        table.clear().draw();
        HideLoadingPanel(gContainer);

        $('#btnSearch').removeAttr("disabled");
        $('span[class~="spinicon"]').attr("hidden", "hidden");      // Hide spin icon
        $('span[class~="normalicon"]').removeAttr("hidden");        // Show normal icon
    }
    else {

        if (table != null || table != undefined)
            table.destroy();

        table = $("#ReassignTable")
            .on('init.dt', function () {    // This event will fire after loading the data in the table
                HideLoadingPanel(gContainer);

                // Reset the buttons
                $('#btnSearch').removeAttr("disabled");
                $('span[class~="spinicon"]').attr("hidden", "hidden");      // Hide spin icon
                $('span[class~="normalicon"]').removeAttr("hidden");        // Show normal icon
            })
            .DataTable({
                data: dataset,
                processing: true,           // To show progress bar 
                serverSide: false,          // To enable processing server side processing (e.g. sorting, pagination, and filtering)
                //filter: true,               // To enable/disable filter (search box)
                orderMulti: false,          // To disable mutiple column sorting
                destroy: true,              // To destroy an old instance of the table and to initialise a new one
                scrollX: true,              // To enable horizontal scrolling
                //sScrollX: "100%",
                //sScrollXInner: "110%",      // This property can be used to force a DataTable to use more width than it might otherwise do when x-scrolling is enabled.
                language: {
                    emptyTable: "No records found in the database."
                },
                //width: "100%",
                lengthMenu: [[5, 10, 20, 50, 100, -1], [5, 10, 20, 50, 100, "All"]],
                pageLength: 10,             // Number of rows to display on a single page when using pagination.
                order: [[1, 'desc']],
                columns: [
                    {
                        title: '<input name="select_all" value="1" id="select-all" type="checkbox"/>',
                        data: "projectNo",
                    },
                    {
                        data: "projectNo",
                        name: "Project No",

                       /* '<label style="width: 130px;">' + '<a href="javascript:void(0)" class="lnkProjectNo gridLink" style="font-size: 14px;" data-projectno=' + row.projectNo + '> ' + row.projectNo + '</a>' + '</label>';*/
                    },
                    {
                        data: "requisitionNo",
                        name: "Requisition No"
                    },
                    {
                        data: "ceaStatusDesc",
                        name: "Status",
                    },
                    {
                         data: "assignedToEmpName",
                         render: function (data) {
                             return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 300px;">' + data + '</label>';
                         }
                    },
                    {
                        data: "requisitionDate",
                        render: function (data) {
                            return '<label style="width: 160px;">' + moment(data).format('DD-MMM-YYYY') + '</label>';
                        }
                    },
                    {
                        data: "costCenter",
                        name: "Cost Center",
                    },
                    {
                        data: "fiscalYear",
                        name: "Fiscal Year",
                    },
                ],
             /*   https://jsfiddle.net/gyrocode/07Lrpqm7/*/
                columnDefs: [
                    {

                        targets: 0,
                        searchable: false,
                        orderable: false,
                        className: 'dt-body-center',
                        render: function (data, type, full, meta) {
                            return '<input type="checkbox" name="id[]" value="'
                                + $('<div/>').text(full.requisitionNo + "," + full.assignedToEmpNo + "," + full.workflowID).html()  + '">'; 
                        }
                    },
                    {
                        targets: "centeredColumn",
                        className: 'dt-body-center'
                    },
                    {
                        targets: 1,     // projectNo
                        render: function (data, type, row) {
                            return '<label style="width: 130px;">' + '<a href="javascript:void(0)" class="lnkProjectNo gridLink" style="font-size: 14px;" data-projectno=' + row.projectNo + '> ' + row.projectNo + '</a>' + '</label>';
                        }
                    },
                    {
                        targets: 2,     // requisitionNo
                        render: function (data, type, row) {
                            return '<label style="width: 130px;">' + '<a href="javascript:void(0)" class="lnkReqNo gridLink" style="color: red; font-size: 14px;" data-requisitionno=' + row.requisitionNo + ' data-assignedtoempno=' + row.assignedToEmpNo + '> ' + row.requisitionNo + '</a>' + '</label>';
                        }
                    },
                    {
                        targets: 3,     // workflowStatus
                        render: function (data, type, row) {
                            //if (row.statusHandlingCode == 'Open') {
                            //    return '<a class="btn btn-sm btn-primary rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + '> ' + row.workflowStatus + '</a>';
                            //}
                            //else if (row.statusHandlingCode == 'Approved' || row.statusHandlingCode == 'PostedJDE') {
                            //    return '<a class="btn btn-sm btn-success rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + '> ' + row.workflowStatus + '</a>';
                            //}
                            //else if (row.statusHandlingCode == 'Cancelled') {
                            //    return '<a class="btn btn-sm btn-warning rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + '> ' + row.workflowStatus + '</a>';
                            //}
                            //else if (row.statusHandlingCode == 'Rejected') {
                            //    return '<a class="btn btn-sm btn-danger rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + '> ' + row.workflowStatus + '</a>';
                            //}
                            //else if (row.statusHandlingCode == 'Closed') {
                            //    return '<a class="btn btn-sm btn-secondary rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + '> ' + row.workflowStatus + '</a>';
                            //}
                            //else if (row.statusHandlingCode == 'Draft') {
                            //    return '<a class="btn btn-sm btn-info rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + '> ' + row.workflowStatus + '</a>';
                            //}
                            //else {
                            //    return '<a class="btn btn-sm btn-info rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + '> ' + row.workflowStatus + '</a>';
                            //}

                            if (row.ceaStatusCode == 'Open') {
                                return '<a class="btn btn-sm btn-primary rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + '> ' + row.ceaStatusDesc + '</a>';
                            }
                            else if (row.ceaStatusCode == 'Approved' || row.ceaStatusCode == 'PostedJDE') {
                                return '<a class="btn btn-sm btn-success rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + '> ' + row.ceaStatusDesc + '</a>';
                            }
                            else if (row.ceaStatusCode == 'Cancelled') {
                                return '<a class="btn btn-sm btn-warning rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + '> ' + row.ceaStatusDesc + '</a>';
                            }
                            else if (row.ceaStatusCode == 'Rejected') {
                                return '<a class="btn btn-sm btn-danger rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + '> ' + row.ceaStatusDesc + '</a>';
                            }
                            else if (row.ceaStatusCode == 'Closed') {
                                return '<a class="btn btn-sm btn-secondary rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + '> ' + row.ceaStatusDesc + '</a>';
                            }
                            else if (row.ceaStatusCode == 'Draft') {
                                return '<a class="btn btn-sm btn-info rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + '> ' + row.ceaStatusDesc + '</a>';
                            }
                            else if (row.ceaStatusCode == 'Submitted') {
                                return '<a class="btn btn-sm btn-primary rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + '> ' + row.ceaStatusDesc + '</a>';
                            }
                            else {
                                return '<a class="btn btn-sm btn-info rounded-pill text-white my-1 gridLink lnkStatus" style="width: 230px; font-size: 12px;" data-requisitionid=' + row.requisitionID + ' data-requisitionno=' + row.requisitionNo + ' data-projectno=' + row.projectNo + ' data-createdno=' + row.createdByEmpNo + ' data-createdname=' + row.createdByEmpName + ' data-submitteddate=' + row.createDate + '> ' + row.ceaStatusDesc + '</a>';
                            }
                        }
                    }           
                ],
                 select: {
                    style: 'multi',
                },
            });

        // Handle click on "Select all" control
        $('#select-all').on('click', function () {

            var rows, checked;
            rows = $('#ReassignTable').find('tbody tr');
            checked = $(this).prop('checked');

            // Check/uncheck all checkboxes in the table
            var rows = table.rows({ 'search': 'applied' }).nodes();
            $('input[type="checkbox"]', rows).prop('checked', checked);
        });

        // Handle click on checkbox to set state of "Select all" control
        $('#ReassignTable tbody').on('change', 'input[type="checkbox"]', function () {
            // If checkbox is not checked
            if (!this.checked) {
                var el = $('input#select-all').get(0);
                // If "Select all" control is checked and has 'indeterminate' property
                if (el && ('indeterminate' in el)) {
                    // Set visual state of "Select all" control as 'indeterminate'
                    el.indeterminate = true;
                }
            }
            else {
                console.log("else condition");
            }
        });
    }
}

function getAllEmployeeList() {

    const searchFilter = new SearchCriterias2();
    searchFilter.empNo = 0;

    $.ajax({
        url: "/UserFunctions/Project/GetEmployeeList",
        type: "GET",
        dataType: "json",
        contentType: "application/json; charset=utf-8",
        cache: false,
        async: true,
        data: searchFilter,
        success:
            function (response, status) {
                if (status == "success") {
                    populateAllEmployeeList(response.data);
                }
                else {
                    throw new Error("Something went wrong while fethcing data from the database!")
                }
            },
        error:
            function (err) {
                throw err;
            }
    });
}

function populateAllEmployeeList(data: any) {

    try {
        if (CheckIfNoValue(data))
            return;

        interface IEmployee {
            label: string;
            value: number;
        }

        const empArray: IEmployee[] = [];
        var item;

        for (var i = 0; i < data.length - 1; i++) {
            item = data[i];

            let empItem = {
                label: item.empNo + " - " + item.empName + " - " + item.email,
                value: item.empNo,
            };

            // Add object to array
            empArray.push(empItem);
        }

        $("#txtOtherEmpNo").autocomplete({
            source: empArray,           // Source should be Javascript array or object
            autoFocus: true,            // Set first item of the menu to be automatically focused when the menu is shown
            minLength: 2,               // The number of characters that must be entered before trying to obtain the matching values. By default its value is 1.
            delay: 300,                 // This option is an Integer representing number of milliseconds to wait before trying to obtain the matching values. By default its value is 300.
            select: function (event, ui) {
                if (ui.item != null && ui.item != undefined) {
                    // Save the employee details to the hidden fields
                    $("#hidOtherEmpNo").val(ui.item.value);

                    // Get the employee name
                    if (ui.item.label.length > 0) {
                        var empArray = ui.item.label.trim().split("-");
                        if (empArray != undefined) {
                            $("#txtOtherEmpNo").val(empArray[0].trim());
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
                    displayErrorAssignment($('#otherEmpValid'), "The specified employee does not exist.", $('#txtOtherEmpNo'));
                    $("#txtOtherEmpNo").focus();
                }
                else
                    $('#otherEmpValid').attr("hidden", "hidden");

                return false;
            }
        });

        $("#txtOtherEmpNo").autocomplete("enable");

        $("#txtNewApproverEmpNo").autocomplete({
            source: empArray,           // Source should be Javascript array or object
            autoFocus: true,            // Set first item of the menu to be automatically focused when the menu is shown
            minLength: 2,               // The number of characters that must be entered before trying to obtain the matching values. By default its value is 1.
            delay: 300,                 // This option is an Integer representing number of milliseconds to wait before trying to obtain the matching values. By default its value is 300.
            select: function (event, ui) {
                if (ui.item != null && ui.item != undefined) {
                    // Save the employee details to the hidden fields
                    $("#hidReassignEmpNo").val(ui.item.value);

                    // Get the employee name
                    if (ui.item.label.length > 0) {
                        var empArray = ui.item.label.trim().split("-");
                        if (empArray != undefined) {
                            $("#txtNewApproverEmpNo").val(empArray[0].trim());
                            $("#hidReassignEmpName").val(empArray[1].trim());
                            $("#hidReassignEmpEmail").val(empArray[2].trim());
                        }
                    }

                    // Hide missing approver error alert
                    $("#otherEmpValid").attr("hidden", "hidden");
                    return false;
                }
            },
            change: function (event, ui) {
                if (ui.item == undefined || ui.item == null) {
                    $("#hidReassignEmpNo").val("");
                    $("input[name='hidReassignEmpName']").val("");
                    $("input[name='hidReassignEmpEmail']").val("");
                    displayErrorAssignment($('#otherEmpValid'), "The specified employee does not exist.", $('#txtNewApproverEmpNo'));
                    $("#txtNewApproverEmpNo").focus();
                }
                else
                    $('#otherEmpValid').attr("hidden", "hidden");

                return false;
            }
        });

        $("#txtNewApproverEmpNo").autocomplete("enable");
    }
    catch (error) {
        HideLoadingPanel(gContainer);
        ShowErrorMessage("The following error has occured executing the populateEmployeeList() function: " + "<b>" + error.message + "</b>")
    }
}

function displayErrorAssignment(obj: any, errText: any, focusObj: any) {
    let alert = $(obj).find(".alert");

    if ($(alert).find(".errorText") != undefined)
        $(alert).find(".errorText").html(errText);

    if (obj != undefined)
        $(obj).removeAttr("hidden");

    $(alert).show();

    if (focusObj != undefined)
        $(focusObj).focus();
}

//#region Action Button Methods
function searchRequisition() {
    var hasError = false;

    // Hide all error alerts
    $('.errorPanel').attr("hidden", "hidden");
    HideErrorMessage();

    ShowLoadingPanel(gContainer, 2, 'Loading requisition data, please wait...');
    LoadRequisitionDataTable();
    container = $('.formWrapper');
    HideLoadingPanel(container);

    // Hide all tool tips
    $('[data-bs-toggle="tooltip"]').tooltip('hide');

}

// #region Database Methods
function LoadRequisitionDataTable() {
    try {
        const searchFilter = new SearchCriterias2();
        gContainer = $('.gridWrapper');

        if (!CheckIfNoValue($('input[name="RequisitionNo"]').val()))
            searchFilter.requisitionNo = $('input[name="RequisitionNo"]').val()!.toString();

        if (!CheckIfNoValue($('#ExpenditureTypeId :selected').text()))
            searchFilter.expenditureType = $('#ExpenditureTypeId :selected').text()?.toString();

        if (!CheckIfNoValue($('#FromFiscalYearId :selected').text()))
            searchFilter.fromFiscalYear = GetIntValue($('#FromFiscalYearId :selected').text()?.toString());

        if (!CheckIfNoValue($('#ToFiscalYearId :selected').text()?.toString()))
            searchFilter.toFiscalYear = GetIntValue($('#ToFiscalYearId :selected').text()?.toString());

        if (!CheckIfNoValue($('#CostCenterId :selected').text()))
            searchFilter.costCenter = GetIntValue($('#CostCenterId :selected').val()?.toString());

        if (!CheckIfNoValue($("#hidOtherEmpNo").val()))
            searchFilter.empNo = GetIntValue($("#hidOtherEmpNo").val()!.toString());

        $.ajax({
            url: "/AdminFunctions/Admin/LoadAssignedRequisitionList",
            type: "GET",
            dataType: "json",
            contentType: "application/json; charset=utf-8",
            cache: false,
            async: true,
            data: searchFilter,
            success:
                function (response, status) {

                    if (response.status == "success") {
                        PopulateReassignmentDataTable(response.data);

                        //if (CheckIfNoValue(response.data)) {
                        //    // Reset the buttons
                        //    $('#btnSearch').removeAttr("disabled");
                        //    $('span[class~="spinicon"]').attr("hidden", "hidden");      // Hide spin icon
                        //    $('span[class~="normalicon"]').removeAttr("hidden");        // Show normal icon

                        //    ShowToastMessage(toastTypes.info, "Sorry, no data found based on the specified search criteria.", "Information");
                        //}
                    }
                    else {
                        HideLoadingPanel(gContainer);
                        $('#btnSearch').removeAttr("disabled");
                        $('span[class~="spinicon"]').attr("hidden", "hidden");      // Hide spin icon
                        $('span[class~="normalicon"]').removeAttr("hidden");        // Show normal icon
                        $('[data-bs-toggle="tooltip"]').tooltip('hide');
                        ShowErrorMessage("Please check the requisition number status should be in 'Submitted' or 'AwaitingChairmanApproval'.");
                    }
                },
            error:
                function (err) {
                    HideLoadingPanel(gContainer);
                    ShowErrorMessage("The following error has occured while executing ReAssignmentDataTable(): " + err.responseText);
                }
        });

    } catch (error) {
        HideLoadingPanel(gContainer);
        ShowErrorMessage("The following error has occured while loading the data to the search results table: " + "<b>" + error.message + "</b>")
    }
}

var selectedRows = new Array();
function GetSelectedRows() {

    table.$('input[type="checkbox"]').each(function () {
        if (this.checked) {
            selectedRows.push(this.value);
        }
    });
}

// Saving the reassign the requisition
function saveButtonClick() {
    
    //let currentAssignedEmpNo = GetStringValue($("#hidUserEmpNo").val());
    let reassignedEmpNo = GetIntValue($('input[name="txtNewApproverEmpNo"').val()); 
    let newApprName = GetStringValue($("#hidReassignEmpName").val());

    var hasError = false;
    GetSelectedRows();
    // Check requisition selected
    if (selectedRows.length == 0) {

        hasError = true;
        // Show notification
        ShowToastMessage(toastTypes.error, "Please select the requisiton number and try again!", "Reassign Unsuccessful");
    }
    else {

        for (let i = 0; i < selectedRows.length; i++) {

            const resquestArray = selectedRows[i].split(',');
            let currentAssignedEmpNo = resquestArray[1];
            //console.log(currentAssignedEmpNo);
            //console.log(reassignedEmpNo);
            // checking whther the selected req. no is assigning to the same approver
            if (currentAssignedEmpNo == reassignedEmpNo) {
                ShowToastMessage(toastTypes.error, "The requisition no. " + resquestArray[0] + " cannot reassign to the same approver !", "Reassign Unsuccessful");
                selectedRows = [];
                hasError = true
                break;
            }
            else {
                /* selectedRows = [];*/
                $('.errorMsgBox').attr("hidden", "hidden");
                $('.errorPanel').attr("hidden", "hidden");
            }
        }
    } 

    // Check Searched Employee
    if (CheckIfNoValue($('input[name="txtNewApproverEmpNo"').val())) {
        displayErrorAssignment($('#othertxtNewApproverEmpValid'), "Please specify the New Approver employee.", $('input[name="txtNewApproverEmpNo"'));
        hasError = true;
    }
    else {
        if ($('#othertxtNewApproverEmpValid').attr("hidden") == undefined)
            $('#othertxtNewApproverEmpValid').attr("hidden", "hidden");
    }

    if (CheckIfNoValue($('#txtRemarks').val())) {
        displayErrorAssignment($('#remarksValid'), "Please specify the reason to change the requisition.", $('#txtRemarks'));
        hasError = true;
    }
    else {
        if ($('#remarksValid').attr("hidden") == undefined)
            $('#remarksValid').attr("hidden", "hidden");
    }


    if (!hasError) {
        //ReassignApprover()
        gContainer = $('.formWrapper');
        ShowLoadingPanel(gContainer, 1, 'Saving information, please wait...');
        ReassignApprover();
        
    }
}

function ReassignApprover() {
    //ShowLoadingPanel(container, 2, 'Loading data...');

    let newAppr: string = $("#hidReassignEmpNo").val()!.toString();
    let newApprName: string = $("#hidReassignEmpName").val()!.toString();
    let newApprEmail: string = $("#hidReassignEmpEmail").val()!.toString();
    let reassignRemarks: string = $("#txtRemarks").val()!.toString();
    let routineSeq = 0;
    let onHold = false;

    gContainer = $('.formWrapper');

    $.ajax({
        url: "/AdminFunctions/Admin/ReassignApprover",
        type: "GET",
        dataType: "json",
        contentType: "application/json; charset=utf-8",
        cache: false,
        async: true,
        data: { selectedRequisition: JSON.stringify(selectedRows), newApproverNo: newAppr, newApprName: newApprName, newApprEmail: newApprEmail, remarks: reassignRemarks, routineSeq: routineSeq, onHold :onHold }, 
        success:
            function (response, status) {
                if (status == "success") {
                    ShowToastMessage(toastTypes.success, "Successfully reassigned to the new approver", "Reassignment Successful");
                    HideLoadingPanel(gContainer);
                    //clear the form  
                    ResetClick();
                    $("#btnReset").click();                    
                }
                else {
                    ShowToastMessage(toastTypes.error, "An error encountered while reassigning the approver.! and Please try again!", "Reassignment Unsuccessful");
                    HideLoadingPanel(gContainer);
                    throw new Error("An error encountered while reassigning the approver.!");
                }
            },
        error:
            function (err) {
                throw err;
            }
    });
}

function showErrorreassign(obj: any, errText: any, focusObj: any) {

    let alert = $(obj).find(".alert");

    if ($(alert).find(".errorText") != undefined)
        $(alert).find(".errorText").html(errText);

    if (obj != undefined)
        $(obj).removeAttr("hidden");

    $(alert).show();

    if (focusObj != undefined)
        $(focusObj).focus();
}

function ResetClick() {
    table = $("#ReassignTable").dataTable().api();
    table.clear().draw;


    return false;
}

function handleReAssignResetButtonClick() {

    let data = "undefined";
    PopulateReassignmentDataTable(data);

    // Hide error alerts
    $('.errorMsgBox').attr("hidden", "hidden");
    $('.errorPanel').attr("hidden", "hidden");
    // Hide all tool tips
    $('[data-bs-toggle="tooltip"]').tooltip('hide');

    $("#btnHiddenReset").click();
}


