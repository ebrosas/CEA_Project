// #region Fields
class ExpenseSearchCriteria {
    constructor() {
        this.requisitionID = 0;
        this.requisitionNo = "";
    }
}
class ExpenseInfo {
    constructor() {
        this.requestedAmt = 0;
        this.poTotal = 0;
        this.glTotal = 0;
        this.balance = 0;
        this.percentageUsed = 0;
    }
}
let expenseListCount = 0;
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
        let newURL = url.replace("RequisitionInquiry", "CEARequisition");
        $('a[class~="backButton"').attr("href", newURL);
    }
    // #endregion
    resetExpenseForm();
    searchButtonExpense();
});
// #endregion
// #region Functional Methods
function resetExpenseForm() {
    // Reset dataTable
    populateExpenseTable(null);
    // Reset the buttons
    $('#btnSearch').removeAttr("disabled");
    $('span[class~="spinicon"]').attr("hidden", "hidden"); // Hide spin icon
    $('span[class~="normalicon"]').removeAttr("hidden"); // Show normal icon
    // Move to the top of the page
    window.scrollTo(0, 0);
    $("#btnHiddenReset").click();
}
function populateExpenseTable(data) {
    var dataset = data;
    if (dataset == "undefined" || dataset == null ||
        (Array.isArray(dataset) && dataset.length == 0)) {
        // Get DataTable API instance
        var table = $("#expenseTable").dataTable().api();
        table.clear().draw();
        HideLoadingPanel(gContainer);
    }
    else {
        let reportTitle = "Expenses Summary Report";
        // Save the table record count
        expenseListCount = dataset.length;
        const expenseInfo = new ExpenseInfo;
        expenseInfo.requestedAmt = GetFloatValue(dataset[0].requestedAmt);
        expenseInfo.poTotal = GetFloatValue(dataset[0].poTotal);
        expenseInfo.glTotal = GetFloatValue(dataset[0].glTotal);
        expenseInfo.balance = GetFloatValue(dataset[0].balance);
        expenseInfo.percentageUsed = GetFloatValue(dataset[0].percentageUsed);
        $("#expenseTable")
            .on('init.dt', function () {
            HideLoadingPanel(gContainer);
            if (expenseListCount > 0) {
                // Display the number of records
                $('span[class~="recordCount"').html("Found <b>" + expenseListCount.toString() + "</b> record(s).");
                $("#txtAmount").val(expenseInfo.requestedAmt.toFixed(3));
                $("#txtPOTotal").val(expenseInfo.poTotal.toFixed(3));
                $("#txtGLTotal").val(expenseInfo.glTotal.toFixed(3));
                $("#txtBalance").val(expenseInfo.balance.toFixed(3));
                $("#lblPercentage").text(expenseInfo.percentageUsed.toFixed(2).concat("% used"));
                if (expenseInfo.percentageUsed > 100) {
                    $("#lblPercentage").removeClass("bg-success");
                    $("#lblPercentage").addClass("bg-danger");
                }
                //$("#txtAmount").val(expenseInfo.requestedAmt.toLocaleString("en-GB"));
                //$("#txtPOTotal").val(expenseInfo.poTotal.toLocaleString("en-GB"));
                //$("#txtGLTotal").val(expenseInfo.glTotal.toLocaleString("en-GB"));
                //$("#txtBalance").val(expenseInfo.balance.toLocaleString("en-GB"));
            }
            else {
                $('span[class~="recordCount"').text("No record found!");
                $("#txtAmount").val("");
                $("#txtPOTotal").val("");
                $("#txtGLTotal").val("");
                $("#txtBalance").val("");
            }
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
            order: [[1, 'asc']],
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
                    data: "costCenter",
                    render: function (data) {
                        return '<label class="d-inline-block text-truncate ps-2 text-center" style="width: 150px;">' + data + '</label>';
                    }
                },
                {
                    data: "orderNumber",
                    render: function (data) {
                        return '<label class="d-inline-block text-truncate ps-2 text-center" style="width: 140px;">' + data + '</label>';
                    }
                },
                {
                    data: "orderDate",
                    render: function (data) {
                        return '<label style="width: 150px;">' + moment(data).format('DD-MMM-YYYY') + '</label>';
                    }
                },
                {
                    data: "lineNo",
                    render: function (data) {
                        return '<label class="d-inline-block text-truncate ps-2 text-center" style="width: 120px;">' + data + '</label>';
                    }
                },
                {
                    data: "description1",
                    render: function (data) {
                        return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 400px;">' + data + '</label>';
                    }
                },
                {
                    data: "description2",
                    render: function (data) {
                        return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 400px;">' + data + '</label>';
                    }
                },
                {
                    data: "vendor",
                    render: function (data) {
                        return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 400px;">' + data + '</label>';
                    }
                },
                {
                    data: "quantity",
                    render: $.fn.dataTable.render.number(',', '.', 3)
                },
                {
                    data: "currencyCode"
                },
                {
                    data: "currencyAmount",
                    render: $.fn.dataTable.render.number(',', '.', 3)
                },
                {
                    data: "poAmount",
                    render: $.fn.dataTable.render.number(',', '.', 3)
                },
                {
                    data: "glAmount",
                    render: $.fn.dataTable.render.number(',', '.', 3)
                },
                {
                    data: "lineTotal",
                    render: $.fn.dataTable.render.number(',', '.', 3)
                },
                {
                    data: "ceaNumber"
                }
            ],
            columnDefs: [
                {
                    targets: "centeredColumn",
                    className: 'dt-body-center'
                },
                //{
                //    targets: 1,     // approverEmpName
                //    render: function (data, type, row) {
                //        return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 400px;">' + '<b>' + data + '</b>' + '<br>' + '<i>' + row.approverPosition + '</i>' + '</label>';
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
function displayErrorExpense(obj, errText, focusObj) {
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
function searchButtonExpense() {
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
        ShowLoadingPanel(gContainer, 2, 'Loading data expense deails, please wait...');
        loadExpenseTable();
    }
}
function resetButtonExpense() {
    // Clear session objects
    DeleteDataFromSession("statusCriteria");
    resetExpenseForm();
}
//#endregion
// #region Database Methods
function loadExpenseTable() {
    var _a;
    try {
        const searchFilter = new ExpenseSearchCriteria();
        if (!CheckIfNoValue((_a = $("#hidRequisitionNo").val()) === null || _a === void 0 ? void 0 : _a.toString()))
            searchFilter.requisitionNo = $("#hidRequisitionNo").val();
        // Save filter criteria to session storage
        let expenseCriteria = GetDataFromSession("expenseCriteria");
        if (CheckIfNoValue(expenseCriteria))
            SaveDataToSession("expenseCriteria", JSON.stringify(searchFilter));
        $.ajax({
            url: "/UserFunctions/Project/GetExpenseTable",
            type: "GET",
            dataType: "json",
            contentType: "application/json; charset=utf-8",
            cache: false,
            async: true,
            data: searchFilter,
            success: function (response, status) {
                if (status == "success") {
                    populateExpenseTable(response.data);
                }
                else {
                    HideLoadingPanel(gContainer);
                    ShowErrorMessage("Unable to load expense detail records from the database, please contact ICT for technical support.");
                }
            },
            error: function (err) {
                HideLoadingPanel(gContainer);
                ShowErrorMessage("The following error has occured while executing loadDataTable(): " + err.responseText);
            }
        });
    }
    catch (error) {
        HideLoadingPanel(gContainer);
        ShowErrorMessage("The following error has occured while fetching data from the database: " + "<b>" + error.message + "</b>");
    }
}
// #endregion
//# sourceMappingURL=expenseDetail.js.map