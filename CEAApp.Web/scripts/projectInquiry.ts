// #region Declare Constants
const CONST_EMPTY = "valEmpty";
const projectInqFormAccess = new UserFormAccess();

interface SearchParameter {
    fiscalYear?: number; 
    projectNo?: string;
    costCenter?: string; 
    expenditureType?: string;
    statusCode?: string;
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
    resetForm();          

    // #region Initialize form secuity
    let userName = GetStringValue($("#hidUserName").val());
    let formCode = GetStringValue($("#hidFormCode").val());

    // Check first if user credentials was already been initialize
    let userCredential = GetDataFromSession("UserCredential");
    if (!CheckIfNoValue(userCredential)) {
        const model = JSON.parse(userCredential!);

        // Initialize the global variable
        gUserAccess.empNo = model.empNo;
        gUserAccess.empName = model.empName;
        gUserAccess.costCenter = model.costCenter;
        gUserAccess.formCode = model.formCode;
        gUserAccess.formName = model.formName;
        gUserAccess.formPublic = model.formPublic;
        gUserAccess.userFrmCRUDP = model.userFrmCRUDP;

        // Get user access information
        GetUserFormAccess(formCode, model.costCenter, model.empNo, PageNameList.ProjectInquiry);
    }
    else {
        GetUserCredential(userName, formCode, PageNameList.ProjectInquiry);
    }        
    // #endregion

    // Check if there was saved search criteria
    let savedData = GetDataFromSession("searchCriteria");
    if (!CheckIfNoValue(savedData)) {
        const data = JSON.parse(savedData!);

        // Bind data to controls
        $("#cboFiscalYear").val(data.fiscalYear);
        $("#txtProjectNo").val(data.projectNo);
        $("#cboCostCenter").val(data.costCenter);
        $("#cboExpenditureType").val(data.expenditureType);
        $("#cboProjectStatus").val(data.statusCode);
        $("#txtKeyword").val(data.keywords);                              
    }

    // Invoke the search button
    searchButtonClick();
});
// #endregion

// #region Public Methods
function resetForm() {    

    // Reset dataTable
    populateDataTable(null);        

    // Reset the buttons
    $('#btnSearch').removeAttr("disabled");
    $('span[class~="spinicon"]').attr("hidden", "hidden");      // Hide spin icon
    $('span[class~="normalicon"]').removeAttr("hidden");        // Show normal icon

    // Move to the top of the page
    window.scrollTo(0, 0);

    $("#btnHiddenReset").click();
}

function populateDataTable(data: any) {
    var dataset = data;

    if (dataset == "undefined" || dataset == null) {
        // Get DataTable API instance
        var table = $("#projectTable").dataTable().api();
        table.clear().draw();

        // Reset the buttons
        $('#btnSearch').removeAttr("disabled");
        $('span[class~="spinicon"]').attr("hidden", "hidden");      // Hide spin icon
        $('span[class~="normalicon"]').removeAttr("hidden");        // Show normal icon                

        HideLoadingPanel(gContainer);                
    }
    else {
        let reportTitle = "Projects Summary Report";

        $("#projectTable")
            .on('init.dt', function () {    // This event will fire after loading the data in the table
                HideLoadingPanel(gContainer);

                // Disable the "Create New" button if user doesn't have insert record access
                if (!HasAccess(gUserAccess.userFrmCRUDP, FormAccessIndex.Create))
                    $('a[class~="createCEAButton"]').addClass("disabled"); 

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
                order: [[3, 'desc']],
                drawCallback: function () {
                    $('.lnkProjectNo').on('click', getProjectDetails);
                    $('a[class~="createCEAButton"]').on('click', openCEAEntry);
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
                        data: "projectNo"
                    },
                    {
                        data: "projectDate",
                        render: function (data) {
                            return '<label style="width: 150px;">' + moment(data).format('DD-MMM-YYYY') + '</label>';
                        }
                    },
                    {
                        data: "expenditureType",                        
                        render: function (data) {
                            return '<label style="width: 150px;">' + data + '</label>';
                        }
                    },
                    {
                        data: "description",
                        render: function (data) {
                            return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 400px;">' + data + '</label>';
                        }
                        /*render: $.fn.dataTable.render.text()*/
                    },
                    {
                        data: "detailDescription",
                        /*render: $.fn.dataTable.render.text()*/
                        render: function (data) {
                            return '<label class="d-inline-block text-truncate ps-2 text-start" style="width: 500px;">' + data + '</label>';
                        }
                    },
                    {
                        data: "accountCode",
                        render: function (data) {
                            return '<label style="width: 180px;">' + data + '</label>';
                        }
                    },
                    {
                        data: "projectStatusDesc",
                        render: function (data) {
                            return '<label style="width: 150px;">' + data + '</label>';
                        }
                    },                    
                    {
                        data: "projectAmount",                        
                        render: $.fn.dataTable.render.number(',', '.', 3)
                    },
                    {
                        data: "projectID"
                    }                    
                ],
                columnDefs: [
                    {
                        targets: "centeredColumn",
                        className: 'dt-body-center'
                    },
                    {
                        targets: 0,     // Create button    
                        render: function (data, type, row) {
                            return '<label style="width: 120px; font-size: 12px;">' + '<a class="btn btn-outline-danger btn-sm w-100 p-0 m-0 createCEAButton" href="javascript:void(0)" data-projectno=' + row.projectNo + '> ' +
                                '<span> <i class="fas fa-plus fa-sm fa-fw" > </i></span >' +
                                "Create" + '</a>' + '</label>';
                        }
                    },
                    {
                        targets: 3,
                        render: function (data, type, row) {
                            return '<label style="width: 130px;">' + '<a href="javascript:void(0)" class="lnkProjectNo gridLink" data-projectno=' + row.projectNo + '> ' + row.projectNo + '</a>' + '</label>';
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

function getProjectDetails() {
    let projectNo: string = $(this).text();

    ShowLoadingPanel(gContainer, 1, 'Loading project details, please wait...');

    // Open the Project Details View
    location.href = "/UserFunctions/Project/ProjectDetail?projectNo=".concat(projectNo);
}

function openCEAEntry() {
    let projectNo: string = $(this).attr("data-projectno") as string;

    ShowLoadingPanel(gContainer, 1, 'Opening CEA request submission page, please wait...');

    // Open the Project Details View
    location.href = "/UserFunctions/Project/CEARequisition?projectNo=".concat(projectNo)
        .concat("&actionType=2")
        .concat("&user_empno=").concat(gUserAccess.empNo.toString())
        .concat("&user_empname=").concat(gUserAccess.empName.trim())
        .concat("&callerForm=").concat(PageControllerMapping.ProjectInquiry.toString());
}

function onlyNumberKey(evt: any) {
    // Only ASCII character in that range allowed
    var ASCIICode = (evt.which) ? evt.which : evt.keyCode
    if (ASCIICode > 31 && (ASCIICode < 48 || ASCIICode > 57))
        return false;
    return true;
} 

function displayAlert(obj: any, errText: any, focusObj: any) {
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
function searchButtonClick() {
    var hasError = false;

    // Hide all error alerts
    $('.errorPanel').attr("hidden", "hidden");
    HideErrorMessage();

    // #region Validate data input
    // Check if Fiscal Year is specified
    //if ($('#cboFiscalYear').val()?.toString().trim() == "") {
    //    displayAlert($('#fiscalYearValid'), "<b>" + $(".fieldLabel label[data-field='FiscalYear']").text() + "</b> is required and cannot be left blank.", $('#cboFiscalYear'));
    //    hasError = true;
    //}
    //else {
    //    if ($('#fiscalYearValid').attr("hidden") == undefined)
    //        $('#fiscalYearValid').attr("hidden", "hidden");
    //}
    // #endregion

    if (!hasError) {
        // Set the current container
        gContainer = $('.gridWrapper');

        // Disable the search button
        $('#btnSearch').attr("disabled", "disabled");

        // Show/hide the spinner icon
        $('span[class~="spinicon"]').removeAttr("hidden");
        $('span[class~="normalicon"]').attr("hidden", "hidden");

        ShowLoadingPanel(gContainer, 2, 'Loading data...');
        loadDataTable();
    }
}

function resetButtonClick() {

    // Clear session objects
    DeleteDataFromSession("searchCriteria");

    resetForm();
}
//#endregion

// #region Database Methods
function loadDataTable() {
    try {

        const searchFilter = {
            fiscalYear: $("#cboFiscalYear").val() !== null && $("#cboFiscalYear").val() !== undefined ? parseInt($("#cboFiscalYear").val()!.toString()) : 0,
            projectNo: $("#txtProjectNo").val()!.toString(),
            costCenter: $("#cboCostCenter").val()!.toString(),
            expenditureType: $("#cboExpenditureType").val()!.toString(),
            statusCode: $("#cboProjectStatus").val()!.toString(),
            keywords: $("#txtKeyword").val()!.toString()
        };

        //  #region Save filter criteria to session storage
        let searchCriteria = GetDataFromSession("searchCriteria");
        if (!CheckIfNoValue(searchCriteria)) {
            // Delete existing data
            DeleteDataFromSession("searchCriteria");
        }

        SaveDataToSession("searchCriteria", JSON.stringify(searchFilter));
        // #endregion

        $.ajax({
            url: "/UserFunctions/Project/LoadProjectList",
            type: "GET",
            dataType: "json",
            contentType: "application/json; charset=utf-8",
            cache: false,
            async: true,
            data: searchFilter,
            success:
                function (response, status) {
                    if (status == "success") {
                        populateDataTable(response.data);

                        if (CheckIfNoValue(response.data)) {
                            // Reset the buttons
                            $('#btnSearch').removeAttr("disabled");
                            $('span[class~="spinicon"]').attr("hidden", "hidden");      // Hide spin icon
                            $('span[class~="normalicon"]').removeAttr("hidden");        // Show normal icon

                            //ShowToastMessage(toastTypes.warning, "No data found for the specified search criteria.", "Warning:");
                        }
                    }
                    else {
                        HideLoadingPanel(gContainer);
                        ShowErrorMessage("Unable to load project requisition records from the database, please contact ICT for technical support.");
                    }
                },
            error:
                function (err) {
                    HideLoadingPanel(gContainer);
                    ShowErrorMessage("The following error has occured while executing loadDataTable(): " + err.responseText);
                }
        });

    } catch (error) {
        HideLoadingPanel(gContainer);
        ShowErrorMessage("The following error has occured while loading the data to the search results table: " + "<b>" + error.message + "</b>")
    }
}
// #endregion

