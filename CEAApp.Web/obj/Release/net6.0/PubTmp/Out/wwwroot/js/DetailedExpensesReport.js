var container = null;

$(function () {

    try {
        container = $('.formWrapper');
        //ShowLoadingPanel(container, 2, 'Loading data...');
        $('#detailedExpenseTable').dataTable({
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
            GetUserFormAccess(formCode, model.costCenter, model.empNo, PageNameList.DetailedExpensesReport);
        }
        else {
            GetUserCredential(userName, formCode, PageNameList.DetailedExpensesReport);
        }
        // #endregion
    }
    catch (error) {

        // Reset the buttons
        $('#btnSearch').removeAttr("disabled");
        $('span[class~="spinicon"]').attr("hidden", "hidden");      // Hide spin icon
        $('span[class~="normalicon"]').removeAttr("hidden");        // Show normal icon
    }
})

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
}
// #end region

function LoadDataTable() {
    try {
        var costCenter = $("#CostCenterId").val();
        var ExpenditureType = $("#ExpenditureTypeId").val();
        var FormFiscalYear = isNaN($("#FormFiscalYearId").val()) ? 0 : parseInt($("#FormFiscalYearId").val().trim());
        var ToFiscalYear = isNaN($("#ToFiscalYearId").val()) ? 0 : parseInt($("#ToFiscalYearId").val());
        var ProjectStatus = $("#projectStatusId option:selected").text();
        var RequisitionStatusId = $("#RequisitionStatus option:selected").val();
        var StartRowIndex = 0;
        var MaximumRows = 0;

        $.ajax({
            url: "/ReportFunctions/Report/LoadDetailedExpenseReport",
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

    }
}

function PopulateDataTable(data) {
    var dataset = data.result;
    var reportTitle = "Expense Report";

    if (dataset == null || dataset == undefined) {
        // Get DataTable API instance
        var table = $("#detailedExpenseTable").dataTable().api();
        table.clear().draw();
        //HideLoadingPanel(container);
    }
    else {
        $("#detailedExpenseTable")
            .on('init.dt', function () {    // This event will fire after loading the data in the table
                HideLoadingPanel(container);

                // Reset the buttons
                $('#btnSearch').removeAttr("disabled");
                $('span[class~="spinicon"]').attr("hidden", "hidden");      // Hide spin icon
                $('span[class~="normalicon"]').removeAttr("hidden");        // Show normal icon
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
                order: [[0, 'desc']],

                //dom: 'Bfrtip',
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
                        data: "projectNo",
                        name: "ProjectNo",
                    },
                    {
                        data: "costCenter",
                        name: "CostCenter",
                    },
                    {
                        data: "fiscalYear",
                        name: "FiscalYear"
                    },
                    {
                        data: "projectDescription",
                        name: "ProjectDescription",
                        render: $.fn.dataTable.render.ellipsis(16, true, true)
                    },
                    {
                        data: "expenditureType",
                        name: "expenditureType"
                    }, 
                    {
                        data: "projectBudget",
                        name: "ProjectBudget"
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
                        data: "requisitionDescription",
                        name: "RequisitionDescription",
                        render: $.fn.dataTable.render.ellipsis(16, true, true)
                    },
                    {
                        data: "requisitionBudget",
                        name: "RequisitionBudget",
                        render: $.fn.dataTable.render.number(',', '.', 3) 
                    },
                    {
                        data: "requisitionStatus",
                        name: "RequisitionStatus"
                    },
                    {
                        data: "purchaseOrderNo",
                        name: "PurchaseOrderNo"
                    },
                    {
                        data: "purchaseOrderLineNo",
                        name: "PurchaseOrderLineNo"
                    },
                    {
                        data: "voucherNo",
                        name: "VoucherNo"
                    },
                    {
                        data: "voucherType",
                        name: "VoucherType"
                    },
                    {
                        data: "voucherPaidAmount",
                        name: "VoucherPaidAmount",
                        render: $.fn.dataTable.render.number(',', '.', 3) 
                    },
                    {
                        data: "voucherItemNo",
                        name: "VoucherItemNo"
                    },
                    {
                        data: "voucherCurrency",
                        name: "VoucherCurrency"
                    },
                    {
                        data: "paymentNo",
                        name: "PaymentNo"
                    },
                    {
                        data: "paymentDate",
                        name: "PaymentDate"
                    },
                    {
                        data: "paymentDocumentType",
                        name: "PaymentDocumentType"
                    },
                    {
                        data: "paymentActualPaidAmount",
                        name: "PaymentActualPaidAmount",
                        render: $.fn.dataTable.render.number(',', '.', 3) 
                    },

                ],
                columnDefs: [
                    {
                        targets: [0, 1, 2, 4, 6, 7, 11, 12, 14, 15, 17, 18, 20],
                        className: "dt-body-center",
                    },
                    {
                        targets: [5, 9,19,21],
                        className: "dt-body-right",
                    },  

                    { targets: 3, width: "250px"},
                ],
                 

            });
    }
}

//#region Loading Panel Methods
function ShowLoadingPanel(container, num, text) {
    ShowWaitMe(container, num, text);
}

function HideLoadingPanel(container) {
    if (container != null && container != undefined)
        HideWaitMe(container);
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