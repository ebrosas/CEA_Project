// #region Fields
class EmployeeSearchCriteria {
    empNo: number;
    empName: string;
    costCenter: string;

    constructor() {
        this.empNo = 0;
        this.empName = "";
        this.costCenter = "";
    }
}

let empListCount = 0;
// #endregion

// #region Document Initialization
$(() => {
    // Set the current container
    gContainer = $('.formWrapper');

    HideLoadingPanel(gContainer);
    HideErrorMessage();

    // Hide all error alerts
    $('.errorPanel').attr("hidden", "hidden");

    //#region Set button event handlers
    $("#btnReset").on("click", function() {
        resetEmployeeForm(); 

        // Clear controls
        $('select[name="CostCenter"]').val("");
    });
    //#endregion

    //#region Set the controller action method of the Back button
    let callerFormVal = $("#hidCallerForm").val();
    let url = $('a[class~="backButton"').attr("href");
    let actionType = GetStringValue($("#hidActionType").val());

    // Append any query string values
    if (!CheckIfNoValue($("#hidQueryString").val())) {
        url = url!.concat($("#hidQueryString").val() as string);
    }

    if (callerFormVal == PageControllerMapping.RequisitionInquiry.toString()) {
        $('a[class~="backButton"').attr("href", url!.concat("?actionType=").concat(actionType));
    }
    else if (callerFormVal == PageControllerMapping.CEARequisition.toString()) {
        $('a[class~="backButton"').attr("href", url!.replace("RequisitionInquiry", PageControllerMapping.CEARequisition.toString()).concat("?actionType=").concat(actionType));
    }
    // #endregion

    resetEmployeeForm();          
    searchButtonEmployee();

    // Set focus to the Search button
    $("#btnSearch").focus();
});
// #endregion

// #region Functional Methods
function resetEmployeeForm() {    

    // Reset dataTable
    populateEmployeeTable(null);        

    // Reset the buttons
    $('#btnSearch').removeAttr("disabled");
    $('span[class~="spinicon"]').attr("hidden", "hidden");      // Hide spin icon
    $('span[class~="normalicon"]').removeAttr("hidden");        // Show normal icon

    // Move to the top of the page
    window.scrollTo(0, 0);

    $("#btnHiddenReset").click();        

    // Set focus to the Search button
    $("#btnSearch").focus();
}

function populateEmployeeTable(data: any) {
    try {

        var dataset = data;
        if (dataset == "undefined" || dataset == null) {
            // Get DataTable API instance
            var table = $("#employeeTable").dataTable().api();
            table.clear().draw();
            HideLoadingPanel(gContainer);
        }
        else {
            let reportTitle = "Expenses Summary Report";

            // Save the table record count
            empListCount = dataset.length;

            $("#employeeTable")
                .on('init.dt', function () {    // This event will fire after loading the data in the table
                    HideLoadingPanel(gContainer);

                    if (empListCount > 0) {
                        // Display the number of records
                        $('span[class~="recordCount"').html("Found <b>" + empListCount.toString() + "</b> record(s).");
                    }
                    else {
                        $('span[class~="recordCount"').text("No record found!")
                    }

                    // Reset the buttons
                    $('#btnSearch').removeAttr("disabled");
                    $('span[class~="spinicon"]').attr("hidden", "hidden");      // Hide spin icon
                    $('span[class~="normalicon"]').removeAttr("hidden");        // Show normal icon
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
                        $('.lnkEmpNo').on('click', getEmployee);
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
                            data: null                            
                        },
                        {
                            data: "empNo",
                            render: function (data) {
                                return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 120px;">' + data + '</label>';
                            }
                        },
                        {
                            data: "empName",
                            render: function (data) {
                                return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 400px;">' + data + '</label>';
                            }
                        },
                        {
                            data: "costCenter",
                            render: function (data) {
                                return '<label class="d-inline-block text-truncate ps-2 text-center" style="width: 120px;">' + data + '</label>';
                            }
                        },
                        {
                            data: "costCenterName",
                            render: function (data) {
                                return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 350px;">' + data + '</label>';
                            }
                        },
                        {
                            data: "dateJoined",
                            render: function (data) {
                                return '<label style="width: 130px;">' + moment(data).format('DD-MMM-YYYY') + '</label>';
                            }
                        },
                        {
                            data: "supervisorFullName",
                            render: function (data) {
                                return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 400px;">' + data + '</label>';
                            }
                        },
                        {
                            data: "email",
                            render: function (data) {
                                return '<label class="d-inline-block text-truncate ps-2 text-center" style="width: 150px;">' + data + '</label>';
                            }
                        }
                    ],
                    columnDefs: [
                        {
                            targets: 0,
                            render: function (data, type, row) {
                                return '<a class="btn btn-sm btn-primary rounded-pill text-white my-1 lnkEmpNo" style="width: 120px;" data-empno=' + row.empNo + ' data-empname=' + encodeURI(row.empName) + '> ' +
                                    '<span> <i class="fas fa-thumbs-up fa-1x fa-fw" > </i></span >' + "&nbsp;" +
                                    "Select" + '</a>' + '</label>';
                            }
                        },
                        {
                            targets: "centeredColumn",
                            className: 'dt-body-center'
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

    } catch (error) {
        HideLoadingPanel(gContainer);
        ShowErrorMessage("The following error has occured while executing the populateEmployeeTable() function: " + "<b>" + error.message + "</b>")
    }    
}

function getEmployee() {
    let empNo: string = "";
    let empName: string = "";
    let actionType = GetStringValue($("#hidActionType").val());
    let projectNo = GetStringValue($("#hidProjectNo").val());
    let prevCallerForm = GetStringValue($("#hidPrevCallerForm").val());

    if (!CheckIfNoValue($(this).attr("data-empno")))
        empNo = $(this).attr("data-empno") as string;

    if (!CheckIfNoValue($(this).attr("data-empname")))
        empName = decodeURI($(this).attr("data-empname") as string);

    ShowLoadingPanel(gContainer, 1, 'Processing selected employee, please wait...');

    let callerFormVal = $("#hidCallerForm").val();
    if (!CheckIfNoValue(callerFormVal)) {
        location.href = "/UserFunctions/Project/".concat(callerFormVal as string)
            .concat("?SearchEmpNo=").concat(empNo)
            .concat("&SearchEmpName=").concat(empName)
            .concat("&user_empno=").concat(gCurrentUser.empNo.toString())
            .concat("&user_empname=").concat(gCurrentUser.empName.trim())
            .concat("&actionType=").concat(actionType)
            .concat("&projectNo=").concat(projectNo)
            .concat("&callerForm=").concat(prevCallerForm);
    }
}

function displayErrorEmployee(obj: any, errText: any, focusObj: any) {
    let alert = $(obj).find(".alert");

    if ($(alert).find(".errorText") != undefined)
        $(alert).find(".errorText").html(errText);

    if (obj != undefined)
        $(obj).removeAttr("hidden");

    $(alert).show();

    if (focusObj != undefined)
        $(focusObj).focus();
}

function onlyNumberKeyEmp(evt: any) {
    // Only ASCII character in that range allowed
    var ASCIICode = (evt.which) ? evt.which : evt.keyCode
    if (ASCIICode > 31 && (ASCIICode < 48 || ASCIICode > 57))
        return false;
    return true;
}
// #endregion

//#region Action Button Methods
function searchButtonEmployee() {
    var hasError = false;

    // Hide all error alerts
    $('.errorPanel').attr("hidden", "hidden");
    HideErrorMessage();

    if (!hasError) {
        // Set the current container
        gContainer = $('.gridWrapper');

        // Disable the search button
        $('#btnSearch').attr("disabled", "disabled");

        // Show/hide the spinner icon
        $('span[class~="spinicon"]').removeAttr("hidden");
        $('span[class~="normalicon"]').attr("hidden", "hidden");

        ShowLoadingPanel(gContainer, 2, 'Loading data...');
        loadEmployeeTable();
    }
}

function resetButtonEmployee() {

    // Clear session objects
    DeleteDataFromSession("empSearchCriteria");

    resetEmployeeForm();
}
//#endregion

// #region Database Methods
function loadEmployeeTable() {
    const searchFilter = new EmployeeSearchCriteria();

    if (!CheckIfNoValue($('input[name="EmpNo"]').val()))
        searchFilter.empNo = GetIntValue($('input[name="EmpNo"]').val());

    if (!CheckIfNoValue($('input[name="EmpName"]').val()))
        searchFilter.empName = $('input[name="EmpName"]').val()!.toString();

    if (!CheckIfNoValue($('select[name="CostCenter"').val()))
        searchFilter.costCenter = $('select[name="CostCenter"').val()!.toString();

    // Save filter criteria to session storage
    let empSearchCriteria = GetDataFromSession("empSearchCriteria");
    if (CheckIfNoValue(empSearchCriteria))
        SaveDataToSession("empSearchCriteria", JSON.stringify(searchFilter));

    $.ajax({
        url: "/UserFunctions/Project/GetEmployeeTable",
        type: "GET",
        dataType: "json",
        contentType: "application/json; charset=utf-8",
        cache: false,
        async: true,
        data: searchFilter,
        success:
            function (response, status) {
                if (status == "success") {
                    populateEmployeeTable(response.data);
                }
                else {
                    HideLoadingPanel(gContainer);
                    ShowErrorMessage("Unable to load employee records from the database, please contact ICT for technical support.");
                }
            },
        error:
            function (err) {
                HideLoadingPanel(gContainer);
                ShowErrorMessage("The following error has occured while executing loadEmployeeTable(): " + err.responseText);
            }
    });
}
// #endregion