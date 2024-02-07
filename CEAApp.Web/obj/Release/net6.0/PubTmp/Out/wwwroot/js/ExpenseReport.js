var container = null;

$(function () {
    try {
        container = $('.formWrapper');
        //ShowLoadingPanel(container, 2, 'Loading data...');
        $('#expenseTable').dataTable({
            "language": {
                "emptyTable": "No data available"
            }
        });
        $("#btnSearch").on("click", SearchButtonClick);

        ShowLoadingPanel(container, 2, 'Loading data...');
        LoadDataTable();

        // #region Initialize form secuity
        let userName = GetStringValue($("#hidUserName").val());
        let formCode = GetStringValue($("#hidFormCode").val());

        // Check first if user credentials was already been initialize
        let userCredential = GetDataFromSession("UserCredential");
        if (!CheckIfNoValue(userCredential)) {
            const model = JSON.parse(userCredential);
            // Get user access information
            GetUserFormAccess(formCode, model.costCenter, model.empNo, PageNameList.ExpensesReport);
        }
        else {
            GetUserCredential(userName, formCode, PageNameList.ExpensesReport);
        }
        // #endregion
    }
    catch (error) {
        //ShowErrorMessage("The following error has occured while loading the page: " + "<b>" + error.message + "</b>")
        HideLoadingPanel(container);

        // Reset the buttons
        $('#btnSearch').removeAttr("disabled");
        $('span[class~="spinicon"]').attr("hidden", "hidden");      // Hide spin icon
        $('span[class~="normalicon"]').removeAttr("hidden");        // Show normal icon
    }
});

function SearchButtonClick() {
    // Set the current container
    container = $('.gridWrapper');

    // Disable the search button
    $('#btnSearch').attr("disabled", "disabled");

    // Show/hide the spinner icon
    $('span[class~="spinicon"]').removeAttr("hidden");
    $('span[class~="normalicon"]').attr("hidden", "hidden");

    ShowLoadingPanel(container, 2, 'Loading data...');
    LoadDataTable();
}

// #region Reset Methods
function ResetButtonClick() {

    // Clear session objects
    DeleteDataFromSession("searchCriteria");
    resetForm();
}

function resetForm() {

    // Reset dataTable
    PopulateDataTable('');

    // Reset the buttons
    $('#btnSearch').removeAttr("disabled");
    $('span[class~="spinicon"]').attr("hidden", "hidden");      // Hide spin icon
    $('span[class~="normalicon"]').removeAttr("hidden");        // Show normal icon

    // Move to the top of the page
    window.scrollTo(0, 0);

    $("#btnHiddenReset").click();
}
// #end region

// #region Database Access Methods
function LoadDataTable() {
    try {
   
        var costCenter = $("#CostCenterId").val();
        var ExpenditureType = $("#ExpenditureTypeId").val();
        var FormFiscalYear = isNaN($("#FormFiscalYearId").val()) ? 0 : parseInt($("#FormFiscalYearId").val().trim()) ;
        var ToFiscalYear = isNaN($("#ToFiscalYearId").val()) ? 0 : parseInt($("#ToFiscalYearId").val());
        var ProjectStatus = $("#projectStatusId option:selected").text();
        var RequisitionStatusId = $('#RequisitionStatus option:selected').val();
        var StartRowIndex = 0;
        var MaximumRows = 0;

        $.ajax({
            url: "/ReportFunctions/Report/LoadExpenseReport",
            type: "GET",        // Note: Set the type to "GET" if the controller parameters are primitive data types; otherwise, set to "POST" if parameter is object
            dataType: "json",
            contentType: "application/json; charset=utf-8",
            cache: "false",
            async: "true",
            data: {
                costCenter: costCenter,
                expenditureType: ExpenditureType,
                fromFiscalYear: FormFiscalYear,
                toFiscalYear: ToFiscalYear,
                projectStatusId: ProjectStatus,
                RequisitionStatusId: RequisitionStatusId,
                startRowIndex: StartRowIndex,
                maximumRows: MaximumRows
            },
            success:
                function (response, status) {                    
                    if (status == "success") {
                        PopulateDataTable(response.data);
                    }
                    else {
                        throw new error("Something went wrong while fethcing data from the database!")
                    }
                },
            error:
                function (err) {
                    throw err;
                }
        });
    }
    catch (error) {
        HideLoadingPanel(container);
        ShowErrorMessage("The following error has occured while loading the data to the search results table: " + "<b>" + error.message + "</b>")
    }
}

function PopulateDataTable(data) {
    var dataset = data.result;
    var reportTitle = "Expense Report";

    if (dataset == null || dataset == undefined) {
        // Get DataTable API instance
        var table = $("#expenseTable").dataTable().api();
        table.clear().draw();
        HideLoadingPanel(container);
    }
    else {
        $("#expenseTable")
            .on('init.dt', function () {    // This event will fire after loading the data in the table
                HideLoadingPanel(container);
            })
            .dataTable({
                data: dataset,
                processing: true,           // To show progress bar 
                serverSide: false,          // To enable processing server side processing (e.g. sorting, pagination, and filtering)
                filter: true,               // To enable/disable filter (search box)
                orderMulti: false,          // To disable mutiple column sorting
                destroy: true,              // To destroy an old instance of the table and to initialise a new one
                scrollX: true,              // To enable horizontal scrolling
                sScrollX: "100%",
                sScrollXInner: "110%",      // This property can be used to force a DataTable to use more width than it might otherwise do when x-scrolling is enabled.
                language: {
                    emptyTable: "No data found"
                },
                width: "100%",
                lengthMenu: [[5, 10, 25, 50, 100, -1], [5, 10, 25, 50, 100, "All"]],
                iDisplayLength: 10,         // Number of rows to display on a single page when using pagination.
                order: [[6, 'desc']],

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
                        titleAttr: 'Print results',
                        title: reportTitle
                    }
                ],

                columns: [
                    {
                        data: "projectNo"
                    },
                    {
                        data: "costCenter",
                        name: "costCenter",

                    },
                    {
                        data: "expenditureType",
                        name: "expenditureType"
                    },
                    {
                        data: "fiscalYear",
                        name: "FiscalYear"
                    },
                    {
                        data: "projectStatus",
                        name: "ProjectStatus"
                    },
                    {
                        data: "requisitionNo",
                        name: "RequisitionNo"
                    },
                    {
                        data: "requisitionDate",
                        name: "RequisitionDate",
                        render: function (data, type, row) {
                            return moment(data).format('DD-MMM-YYYY');
                        }
                    },
                    {
                        data: "budget",
                        name: "Budget",
                        render: $.fn.dataTable.render.number(',', '.', 3)
                    },
                    {
                        data: "requisitionDescription",
                        name: "RequisitionDescription",
                        render: $.fn.dataTable.render.ellipsis(30, true, true)
                    },

                    {
                        data: "requisitionStatus",
                        name: "RequisitionStatus"
                    },
                    {
                        data: "openAmount",
                        name: "OpenAmount",
                        render: $.fn.dataTable.render.number(',', '.', 3)
                    },
                    {
                        data: "glAmount",
                        name: "GlAmount"
                    },
                    {
                        data: "balance",
                        name: "Balance",
                        render: $.fn.dataTable.render.number(',', '.', 3)
                    },                   
                ],
                columnDefs: [
                    {
                        targets: [0, 1, 2, 3, 4, 5, 6],
                        className: "dt-body-center",
                    },
                    {
                        targets: [7, 9, 10, 11, 12],
                        className: "dt-body-right",
                    },   
                    { width: "120px", targets: 10 },
                    { width: "120px", targets: 11 },
                    { width: "120px", targets: 12 },
                    { width: "15px", targets: 13 },
                    {
                        targets: [13],
                        render: function (data, type, row) {

                            if (row.balance >= 0) {
                                return '<input type="button" width="10px" height="5px" alt="' + row.balance +'" style="background-color: #4CAF50;width:10px;" />'
                            } else {

                                return '<input type="button" width="10px" height="5px" alt="' + row.balance + '" style="background-color: #f44336;width:10px;" />'
                            }
                        }
                    },
                ]
  
            });
    }
}

function ExcelExportClick() {
    // Set the current container
    container = $('.gridWrapper');

    ShowLoadingPanel(container, 2, 'Loading data...');
    ExportExcelLoadDataTable();

    event.stopPropagation();
}


function ExportExcelLoadDataTable() {

    try {

        var costCenter = $("#CostCenterId").val();
        var ExpenditureType = $("#ExpenditureTypeId").val();
        var FormFiscalYear = isNaN($("#FormFiscalYearId").val()) ? 0 : parseInt($("#FormFiscalYearId").val().trim());
        var ToFiscalYear = isNaN($("#ToFiscalYearId").val()) ? 0 : parseInt($("#ToFiscalYearId").val());
        var ProjectStatus = $("#projectStatusId option:selected").text();
        var RequisitionStatusIds = 0;
        var StartRowIndex = 0;
        var MaximumRows = 0;

        $.ajax({
            url: "/ReportFunctions/Report/ExcelExportExpenseReport",
            type: "GET",        // Note: Set the type to "GET" if the controller parameters are primitive data types; otherwise, set to "POST" if parameter is object
            dataType: "json",
            contentType: "application/json; charset=utf-8",
            cache: "false",
            async: "true",
            data: {
                costCenter: costCenter,
                expenditureType: ExpenditureType,
                fromFiscalYear: FormFiscalYear,
                toFiscalYear: ToFiscalYear,
                projectStatusId: ProjectStatus,
                RequisitionStatusIds: RequisitionStatusIds,
                startRowIndex: StartRowIndex,
                maximumRows: MaximumRows
            },
            success:
                function (response, status) {
                    if (status == "success") {
                        PopulateDataTable(response.data);
                    }
                    else {
                        throw new error("Something went wrong while fethcing data from the database!")
                    }
                },
            error:
                function (err) {
                    throw err;
                }
        });
    }
    catch (error) {
        HideLoadingPanel(container);
        ShowErrorMessage("The following error has occured while loading the data to the search results table: " + "<b>" + error.message + "</b>")
    }
}

//#region Loading Panel Methods
function ShowLoadingPanel(container, num, text) {
    ShowWaitMe(container, num, text);
}

function HideLoadingPanel(container) {
    if (container != null && container != undefined)
        HideWaitMe(container);

        // Reset the buttons
        $('#btnSearch').removeAttr("disabled");
        $('span[class~="spinicon"]').attr("hidden", "hidden");      // Hide spin icon
        $('span[class~="normalicon"]').removeAttr("hidden");        // Show normal icon
}

function ShowWaitMe(container, num, text) {
    var effect = '',
        maxSize = '',
        fontSize = '',
        color = '',             // Color for background animation and text (string).
        textPos = ''            // Options: 'vertical' | 'horizontal'

    switch (num) {
        case 1: // Entire form
            effect = 'win8',
            maxSize = '200';
            fontSize = '20px';
            color = '#1E4A6D';
            textPos = 'vertical';
            break;

        case 2: // Selected section
            effect = 'stretch';
            maxSize = '200';
            fontSize = '14px';
            color = '#3F92B7', //'#000',
            textPos = 'horizontal';
            break;
    }

    if (container != null || container != undefined) {
        container.waitMe({
            effect: effect,
            text: text,
            bg: 'rgba(255,255,255,0.8)',
            color: color,
            maxSize: maxSize,
            source: '',
            textPos: textPos,
            fontSize: fontSize,
            waitTime: -1,
            onClose: function () { }
        });
    }
}

function HideWaitMe(container) {
    if (container != null || container != undefined) {
        container.waitMe('hide');
    }
}

//#endregion