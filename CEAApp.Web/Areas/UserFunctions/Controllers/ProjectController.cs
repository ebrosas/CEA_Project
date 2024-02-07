using CEAApp.Web.DIServices;
using CEAApp.Web.Models;
using CEAApp.Web.Repositories;
using iText.Html2pdf;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using Newtonsoft.Json;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.ServiceModel;
using System.ServiceModel.Description;
using System.Text.Encodings.Web;
using WFServiceProxy;
using static CEAApp.Web.Models.GlobalSettings;
using static Microsoft.Extensions.Logging.EventSource.LoggingEventSource;
//using RequestWFItem = CEAApp.Web.Models.RequestWFItem;

namespace CEAApp.Web.Areas.UserFunctions.Controllers
{
    [Area("UserFunctions")]
    public class ProjectController : Controller
    {
        #region Fields
        private readonly IProjectRepository _repository;
        private readonly IConverterService _converter;
        private readonly ApplicationDbContext _context;
        private readonly IConfiguration _config;
        private readonly SecurityController _securityController;

        private enum SearchRequisitionType
        {
            ASGNTOME,       // Show requisitions assigned to me
            ASGNTOALL,      // Show requisitions assigned to all
            ASGNTOOTHR      // Show requisitions assigned to others
        }

        private enum LookupTableType
        {
            CEAREQUISITION          // Load datasource for all comboboxes in CEA Requisition form
        }

        private enum ButtonAction
        {
            NotSet,
            Draft,
            Submit,
            Delete,
            Reject,
            Approve,
            Print
        }

        private enum WorkflowStatus
        {
            ACTIVITY_STATUS_UNKNOWN = 0,
            ACTIVITY_STATUS_CREATED = 106,
            ACTIVITY_STATUS_IN_PROGRESS = 107,
            ACTIVITY_STATUS_SKIPPED = 108,
            ACTIVITY_STATUS_COMPLETED = 109
        }

        private enum DBResultStatus
        {
            DB_STATUS_ERROR = -1,
            DB_STATUS_ERROR_DUPLICATE = -2,
            DB_STATUS_ERROR_NOT_CURRENT_DIST_MEMBER = -100,
            DB_STATUS_ERROR_NO_COST_CENTER_APPROVAL = -10,
            DB_STATUS_OK = 0
        }
        #endregion

        #region Constructors
        public ProjectController(ApplicationDbContext context, IProjectRepository repository, IConverterService converter, IConfiguration configuration, SecurityController securityController)
        {
            _context = context;
            _repository = repository;
            _converter = converter;
            _config = configuration;
            _securityController = securityController;
        }
        #endregion

        #region Properties
        [BindProperty(SupportsGet = true)]
        public string? CallerForm { get; set; } = null!;

        [BindProperty(Name = "prevCallerForm", SupportsGet = true)]
        public string? PreviousCallerForm { get; set; } = null!;

        [BindProperty(SupportsGet = true)]
        public int? SearchEmpNo { get; set; } = null!;

        [BindProperty(SupportsGet = true)]
        public string? SearchEmpName { get; set; } = null!;

        [BindProperty(SupportsGet = true)]
        public string? ActionType { get; set; } = null!;

        [BindProperty(Name = "user_empno", SupportsGet = true)]
        public int? CurrentUserEmpNo { get; set; } = null!;

        [BindProperty(Name = "user_empname", SupportsGet = true)]
        public string? CurrentUserEmpName { get; set; }

        [BindProperty(SupportsGet = true)]
        public string? ProjectNo { get; set; }

        [BindProperty(Name = "invoke_search", SupportsGet = true)]
        public bool? InvokeSearch { get; set; } = null!;

        [BindProperty(Name = "ignore_save", SupportsGet = true)]
        public bool? IgnoreSavedData { get; set; } = null!;

        [BindProperty(Name = "toastmsg", SupportsGet = true)]
        public string? ToastNotification { get; set; }

        private CommonWFServiceClient WorkflowServiceProxy
        {
            get
            {
                try
                {
                    var appSettingOptions = new AppSettingOptions();
                    _config.GetSection(AppSettingOptions.AppSettings).Bind(appSettingOptions);

                    string DynamicEndpointAddress = appSettingOptions.WFEngineURL;
                    //BasicHttpBinding customBinding = GlobalSettings.GetCustomBinding();
                    BasicHttpBinding customBinding = new BasicHttpBinding();
                    customBinding.Name = "BasicHttpEndpointAnonymousBinding";

                    EndpointAddress endpointAddress = new EndpointAddress(DynamicEndpointAddress);
                    CommonWFServiceClient proxy = new CommonWFServiceClient(customBinding, endpointAddress);

                    #region Set the value of MaxItemsInObjectGraph to maximum so that the service can receive large files
                    try
                    {
                        foreach (OperationDescription op in proxy.ChannelFactory.Endpoint.Contract.Operations)
                        {
                            var dataContractBehavior = op.Behaviors.Find<DataContractSerializerOperationBehavior>();
                            if (dataContractBehavior != null)
                            {
                                dataContractBehavior.MaxItemsInObjectGraph = int.MaxValue;
                            }
                        }
                    }
                    catch (Exception)
                    {
                    }
                    #endregion

                    return proxy;
                }
                catch (Exception)
                {
                    return null;
                }
            }
        }
        #endregion

        #region Impersonation properties
        public const string SessionDefaultUser = "_FirstUser";
        public const string SessionEmpName = "_EmpName";
        public const string SessionUserID = "_UserID";
        public const string SessionEmpNo = "_EmpNo";
        public const string SessionCostCenter = "_CostCenter";
        #endregion

        #region Public Methods
        /// <summary>
        /// This method is used to initialize the Projects Inquiry page 
        /// Web Method: GET => UserFunctions/Project/Index
        /// </summary>
        /// <returns></returns>        
        public async Task<IActionResult> Index()
        {
            ProjectViewModel? projectVM = null;

            try
            {
                #region Test consuming the WCF service
                //string ceaNo = "20220024";
                //int userEmpNo2 = 10003632;
                //string userEmpName2 = "ERVIN BROSAS";
                //string userID2 = "ervin";

                //DBTransResult? dbResult = await _repository.RunWorkflowProcess(ceaNo, userEmpNo2, userEmpName2, userID2);
                //if (dbResult != null && dbResult.HasError)
                //{

                //}
                #endregion

                List<SelectListItem> fiscalYearArray = new List<SelectListItem>();
                List<SelectListItem> costCenterArray = new List<SelectListItem>();
                List<SelectListItem> projectStatusArray = new List<SelectListItem>();
                List<SelectListItem> expenditureTypeArray = new List<SelectListItem>();
                List<SelectListItem> expenseTypeArray = new List<SelectListItem>();
                int defaultFiscalYear = DateTime.Now.Year;

                #region Get the current logged-on user information
                string userID = TempData["UserID"] != null ? _converter.ConvertObjectToString(TempData.Peek("UserID")!) : string.Empty;
                string userCostCenter = TempData["UserCostCenter"] != null ? _converter.ConvertObjectToString(TempData.Peek("UserCostCenter")!) : string.Empty;
                int? userEmpNo = TempData["UserEmpNo"] != null ? _converter.ConvertObjectToInt(TempData.Peek("UserEmpNo")!) : 0;                

                if (userEmpNo == 0)
                {
                    // Initialize impersonator
                    TempData["Impersonator"] = null;

                    EmployeeInfo? empInfo = InitializeUserInfo();
                    if (empInfo != null)
                    {
                        // Get the user cost center
                        userCostCenter = empInfo.CostCenter!;

                        // Define the session variables that will store the employee no. and cost center of the user
                        TempData["UserID"] = empInfo.UserID;
                        TempData["UserEmpNo"] = empInfo.EmpNo;
                        TempData["UserEmpName"] = empInfo.EmpName;
                        TempData["UserCostCenter"] = empInfo.CostCenter!;
                        TempData["ComputerName"] = Environment.MachineName.ToString();
                    }
                }
                #endregion

                #region Populate lookup tables
                var model = await _repository.GetLookupTable();
                if (model != null)
                {                    
                    // Populate Fiscal Year collection
                    if (model.FiscalYearList != null)
                    {
                        foreach (var item in model.FiscalYearList!)
                        {
                            fiscalYearArray.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                        }

                        if (fiscalYearArray.Where(o => Convert.ToInt32(o.Value) == defaultFiscalYear).FirstOrDefault() == null)
                        {
                            defaultFiscalYear = Convert.ToInt32(fiscalYearArray.Max(o => o.Value));
                        }
                    }

                    if (model.CostCenterList != null)
                    {
                        // Populate Cost Center collection
                        foreach (var item in model.CostCenterList!)
                        {
                            //costCenterArray.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription.Replace('&', ' ').Replace('#', ' ').Replace('/', ' ') });
                            costCenterArray.Add(new SelectListItem { Value = item.UDCValue, Text = HtmlEncoder.Default.Encode(item.UDCDescription) });
                        }

                        // Store object to session
                        //TempData["CostCenterArray"] = JsonConvert.SerializeObject(costCenterArray);
                    }

                    if (model.ProjectStatusList != null)
                    {
                        //Populate Project Status collection
                        foreach (var item in model.ProjectStatusList!)
                        {
                            projectStatusArray.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                        }

                        // Store object to session
                        //TempData["ProjectStatusArray"] = JsonConvert.SerializeObject(projectStatusArray);
                    }

                    if (model.ExpenditureTypeList != null)
                    {
                        // Populate Project Status collection
                        foreach (var item in model.ExpenditureTypeList!)
                        {
                            expenditureTypeArray.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                        }

                        // Store object to session
                        //TempData["ExpenditureTypeArray"] = JsonConvert.SerializeObject(expenditureTypeArray);
                    }

                    if (model.ExpenseTypeList != null)
                    {
                        // Populate Project Status collection
                        foreach (var item in model.ExpenseTypeList!)
                        {
                            expenseTypeArray.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                        }

                        // Store object to session
                        //TempData["ExpenseTypeArray"] = JsonConvert.SerializeObject(expenseTypeArray);
                    }
                }
                #endregion

                // Initialize the model to be returned to the view
                projectVM = new ProjectViewModel()
                {
                    FiscalYearArray = fiscalYearArray,
                    CostCenterArray = costCenterArray,
                    ProjectStatusArray = projectStatusArray,
                    ExpenditureTypeArray = expenditureTypeArray,
                    ProjectStatus = "Active",
                    FiscalYear = defaultFiscalYear.ToString(), //DateTime.Now.Year.ToString(),
                    CostCenter = userCostCenter,
                    FormCode = CEAFormCodes.PROJECTINQ.ToString()
                    //JavascriptToRun = "viewHideLoadingPanel(gContainer)"        // Notes: Pass the name of a Javascript function that will be called in the view)
                };                                
            }
            catch (Exception ex)
            {
                projectVM = new ProjectViewModel()
                {
                    ErrorMessage = ex.Message.ToString()
                };
            }

            return View(projectVM);
        }

        /// <summary>
        /// This method is used to load the project details
        /// Web Method: GET => UserFunctions/Project/ProjectDetails
        /// </summary>
        /// <returns></returns>
        public async Task<IActionResult> ProjectDetail(string projectNo)
        {
            ProjectViewModel projectVM = new ProjectViewModel() {
                ErrorMessage = string.Empty,
                NotificationMessage = string.Empty
            };

            try
            {
                #region Get the current logged-on user information
                int? userEmpNo = TempData["UserEmpNo"] != null ? _converter.ConvertObjectToInt(TempData.Peek("UserEmpNo")!) : 0;
                if (userEmpNo == 0)
                {
                    // Initialize impersonator
                    TempData["Impersonator"] = null;

                    EmployeeInfo? empInfo = InitializeUserInfo();
                    if (empInfo != null)
                    {
                        // Define the session variables that will store the employee no. and cost center of the user
                        TempData["UserID"] = empInfo.UserID;
                        TempData["UserEmpNo"] = empInfo.EmpNo;
                        TempData["UserEmpName"] = empInfo.EmpName;
                        TempData["UserCostCenter"] = empInfo.CostCenter!;
                        TempData["ComputerName"] = Environment.MachineName.ToString();
                    }
                }
                #endregion

                // Save the caller form into the VM
                if (!string.IsNullOrEmpty(this.CallerForm))
                {
                    projectVM.CallerForm = this.CallerForm;

                    // Store data to session
                    TempData["CallerForm"] = this.CallerForm;
                }

                if (string.IsNullOrWhiteSpace(projectNo))
                {
                    // Fetch data from session
                    projectNo = _converter.ConvertObjectToString(TempData["ProjectNo"]!);
                }

                if (string.IsNullOrWhiteSpace(projectNo))
                {
                    projectVM.ErrorMessage = "Project No. is not defined!";
                    goto Exit_Here;
                }

                // Get the project details from DB
                ProjectInfo projectDetail = _repository.GetProjectDetail(projectNo.Trim());
                if (projectDetail == null)
                {
                    projectVM.ErrorMessage = "No record found in the database.";
                    goto Exit_Here;
                }

                // Store the Project No. to the View Bag                
                TempData["ProjectNo"] = projectNo;

                // Get session data
                string? toastNotification = TempData["ToastNotification"] != null ? _converter.ConvertObjectToString(TempData["ToastNotification"]!)
                    : !string.IsNullOrEmpty(this.ToastNotification) ? this.ToastNotification : null;

                // Store project detail into viewmodel
                projectVM.ProjectDetail = projectDetail;

                if (!string.IsNullOrEmpty(toastNotification))
                    projectVM.ToastNotification = toastNotification;

                #region Initialize lookup data
                List<SelectListItem> fiscalYearArray = new List<SelectListItem>();
                List<SelectListItem> costCenterArray = new List<SelectListItem>();
                List<SelectListItem> projectStatusArray = new List<SelectListItem>();
                List<SelectListItem> expenditureTypeArray = new List<SelectListItem>();
                List<SelectListItem> expenseTypeArray = new List<SelectListItem>();

                var model = await _repository.GetLookupTable();
                if (model != null)
                {
                    // Populate Fiscal Year collection
                    if (model.FiscalYearList != null)
                    {
                        foreach (var item in model.FiscalYearList!)
                        {
                            fiscalYearArray.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                        }
                    }

                    if (model.CostCenterList != null)
                    {
                        // Populate Cost Center collection
                        foreach (var item in model.CostCenterList!)
                        {
                            costCenterArray.Add(new SelectListItem { Value = item.UDCValue, Text = HtmlEncoder.Default.Encode(item.UDCDescription) });
                        }
                    }

                    if (model.ProjectStatusList != null)
                    {
                        //Populate Project Status collection
                        foreach (var item in model.ProjectStatusList!)
                        {
                            projectStatusArray.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                        }
                    }

                    if (model.ExpenseTypeList != null)
                    {
                        // Populate Project Status collection
                        foreach (var item in model.ExpenseTypeList!)
                        {
                            expenseTypeArray.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                        }
                    }
                }

                // Store collections into viewmodel
                projectVM.FiscalYearArray = fiscalYearArray;
                projectVM.CostCenterArray = costCenterArray;
                projectVM.ProjectStatusArray = projectStatusArray;
                projectVM.ExpenseTypeArray = expenseTypeArray;
                projectVM.FormCode = CEAFormCodes.PROJDETAIL.ToString();
                #endregion

                Exit_Here:
                return View(projectVM);
            }
            catch (Exception ex)
            {
                projectVM = new ProjectViewModel()
                {
                    ProjectDetail = null,
                    ErrorMessage = ex.Message.ToString()
                };
            }

            return View(projectVM);
        }

        /// <summary>
        /// This method is used to post the changes in the project details into the database
        /// </summary>
        /// <param name="id"></param>
        /// <param name="projectDetail"></param>
        /// <returns></returns>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ProjectDetail([Bind("ProjectID,ProjectNo,FiscalYear,ExpectedProjectDate,AccountCode,ObjectCode,SubjectCode,CostCenter,ExpenditureType,ProjectAmount,Description,DetailDescription")] ProjectInfo project)
        {
            ProjectViewModel projectVM = new ProjectViewModel()
            {
                ErrorMessage = string.Empty,
                NotificationMessage = string.Empty
            };

            if (!ModelState.IsValid)
            {
                projectVM.ErrorMessage = "Unable to save data changes due to validation error.";
                return View(projectVM);
            }

            DBTransResult dbResult = await _repository.InsertUpdateDeleteProject(ProjectRepository.DataAccessType.Update, project);
            if (!dbResult.HasError)
            {
                projectVM.ErrorMessage = dbResult.ErrorDesc;

                // Display successful notification
                TempData["ToastNotification"] = "Project details have been updated successfully!";
            }

            return RedirectToAction(nameof(ProjectDetail));
        }

        /// <summary>
        /// This method is used to render the Requisition Inquiry page 
        /// Web Method: GET => UserFunctions/Project/RequisitionInquiry
        /// </summary>
        /// <returns></returns>        
        public async Task<IActionResult> RequisitionInquiry(int? filterFiscalYear, string? filterCostCenter, string? filterCEANo)
        {
            ProjectViewModel? projectVM = null;

            try
            {
                List<SelectListItem> fiscalYearArray = new List<SelectListItem>();
                List<SelectListItem> costCenterArray = new List<SelectListItem>();
                List<SelectListItem> projectStatusArray = new List<SelectListItem>();
                List<SelectListItem> expenditureTypeArray = new List<SelectListItem>();
                List<SelectListItem> reqStatusArray = new List<SelectListItem>();
                List<SelectListItem> approvalTypeArray = new List<SelectListItem>();
                int defaultFiscalYear = DateTime.Now.Year;

                #region Get the current logged-on user information
                string userCostCenter = _converter.ConvertObjectToString(TempData.Peek("UserCostCenter")!);
                int? userEmpNo = TempData["UserEmpNo"] != null ? _converter.ConvertObjectToInt(TempData.Peek("UserEmpNo")!) : 0;
                
                if (userEmpNo == 0)
                {
                    // Initialize impersonator
                    TempData["Impersonator"] = null;

                    EmployeeInfo? empInfo = InitializeUserInfo();
                    if (empInfo != null)
                    {
                        // Get the current logged-on user cost center
                        userEmpNo = empInfo.EmpNo;
                        userCostCenter = empInfo.CostCenter!;

                        // Define the session variables that will store the employee no. and cost center of the user
                        TempData["UserID"] = empInfo.UserID;
                        TempData["UserEmpNo"] = empInfo.EmpNo;
                        TempData["UserEmpName"] = empInfo.EmpName;
                        TempData["UserCostCenter"] = empInfo.CostCenter!;
                        TempData["ComputerName"] = Environment.MachineName.ToString();
                    }
                }
                #endregion

                #region Populate comboboxes
                var model = await _repository.GetLookupTable();
                if (model != null)
                {
                    // Populate Fiscal Year collection
                    if (model.FiscalYearList != null)
                    {
                        foreach (var item in model.FiscalYearList!)
                        {
                            fiscalYearArray.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                        }

                        if (fiscalYearArray.Where(o => Convert.ToInt32(o.Value) == defaultFiscalYear).FirstOrDefault() == null)
                        {
                            defaultFiscalYear = Convert.ToInt32(fiscalYearArray.Max(o => o.Value));
                        }
                    }

                    if (model.CostCenterList != null)
                    {
                        // Populate Cost Center collection
                        foreach (var item in model.CostCenterList!)
                        {
                            costCenterArray.Add(new SelectListItem { Value = item.UDCValue, Text = HtmlEncoder.Default.Encode(item.UDCDescription) });
                        }
                    }

                    if (model.ProjectStatusList != null)
                    {
                        //Populate Project Status collection
                        foreach (var item in model.ProjectStatusList!)
                        {
                            projectStatusArray.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                        }
                    }

                    if (model.ExpenditureTypeList != null)
                    {
                        // Populate Project Status collection
                        foreach (var item in model.ExpenditureTypeList!)
                        {
                            expenditureTypeArray.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                        }
                    }

                    if (model.RequisitionStatusList != null)
                    {
                        // Populate Requisition Status collection
                        foreach (var item in model.RequisitionStatusList!)
                        {
                            reqStatusArray.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                        }                                                
                    }

                    if (model.ApprovalTypeList != null)
                    {
                        // Populate Requisition Status collection
                        foreach (var item in model.ApprovalTypeList!)
                        {
                            approvalTypeArray.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                        }
                    }
                }
                #endregion

                // Initialize search criteria                
                SearchCriteria searcFilter = new SearchCriteria()
                {
                    FiscalYear = defaultFiscalYear,
                    CostCenter = userCostCenter,
                    EmpNo = userEmpNo,
                    Status = GlobalSettings.CEAStatusCode.DraftAndSubmitted.ToString(),
                    SearchEmpNo = this.SearchEmpNo,
                    SearchEmpName = this.SearchEmpName
                };

                if (_converter.ConvertObjectToInt(filterFiscalYear!) > 0)
                    searcFilter.FiscalYear = _converter.ConvertObjectToInt(filterFiscalYear!)!;

                if (!string.IsNullOrEmpty(filterCostCenter))
                    searcFilter.CostCenter = filterCostCenter;

                if (!string.IsNullOrEmpty(filterCEANo))
                    searcFilter.RequisitionNo = filterCEANo;

                // Get the session values
                byte? invokeSearch = TempData["InvokeSearch"] != null ? _converter.ConvertObjectToByte(TempData["InvokeSearch"]!) 
                    : this.InvokeSearch.HasValue && this.InvokeSearch == true ? 1 : null;

                string? toastNotification = TempData["ToastNotification"] != null ? _converter.ConvertObjectToString(TempData["ToastNotification"]!)
                    : !string.IsNullOrEmpty(this.ToastNotification) ? this.ToastNotification : null;

                byte? ignoreSavedData = TempData["IgnoreSavedData"] != null ? _converter.ConvertObjectToByte(TempData["IgnoreSavedData"]!)
                    : this.IgnoreSavedData.HasValue && this.IgnoreSavedData == true ? 1 : null;

                // Initialize the model to be returned to the view
                projectVM = new ProjectViewModel()
                {
                    FiscalYearArray = fiscalYearArray,
                    CostCenterArray = costCenterArray,
                    ProjectStatusArray = projectStatusArray,
                    ExpenditureTypeArray = expenditureTypeArray,
                    RequisitionStatusArray = reqStatusArray,
                    ApprovalTypeArray = approvalTypeArray,
                    SearchFilter = searcFilter,
                    FormCode = CEAFormCodes.REQUESTINQ.ToString(),
                    InvokeSearch = invokeSearch,
                    ToastNotification = toastNotification,
                    IgnoreSavedData = ignoreSavedData
                };
            }
            catch (Exception ex)
            {
                projectVM = new ProjectViewModel()
                {
                    ErrorMessage = ex.Message.ToString()
                };
            }

            return View(projectVM);
        }

        public ActionResult RequisitionStatusView(int requisitionID, string projectNo, string requisitionNo, string createdNo, string createdName, string submittedDate, string actionType, bool useNewWF)
        {
            try
            {
                #region Get the current logged-on user information
                int? userEmpNo = TempData["UserEmpNo"] != null ? _converter.ConvertObjectToInt(TempData.Peek("UserEmpNo")!) : 0;
                if (userEmpNo == 0)
                {
                    // Initialize impersonator
                    TempData["Impersonator"] = null;

                    EmployeeInfo? empInfo = InitializeUserInfo();
                    if (empInfo != null)
                    {
                        // Define the session variables that will store the employee no. and cost center of the user
                        TempData["UserID"] = empInfo.UserID;
                        TempData["UserEmpNo"] = empInfo.EmpNo;
                        TempData["UserEmpName"] = empInfo.EmpName;
                        TempData["UserCostCenter"] = empInfo.CostCenter!;
                        TempData["ComputerName"] = Environment.MachineName.ToString();
                    }
                }
                #endregion

                RequisitionStatusVM requestVM = new RequisitionStatusVM() 
                { 
                    ErrorMessage = string.Empty, 
                    NotificationMessage = string.Empty,
                    RequisitionID = requisitionID,
                    ProjectNo = projectNo,
                    RequisitionNo = requisitionNo,
                    CreatedBy = $"({createdNo}) {createdName}",
                    SubmittedDate = _converter.ConvertObjectToDate(submittedDate),
                    UseNewWF = useNewWF
                };

                // Save the caller form into the VM
                if (!string.IsNullOrEmpty(this.CallerForm))
                {
                    requestVM.CallerForm = this.CallerForm;
                }

                #region Set Query String
                if (!string.IsNullOrEmpty(requisitionNo))
                {
                    requestVM.QueryString = $"?requisitionNo={requisitionNo}";                                            
                }

                if (!string.IsNullOrEmpty(actionType))
                {
                    if (string.IsNullOrEmpty(requestVM.QueryString))
                        requestVM.QueryString = $"?actionType={actionType}";
                    else
                        requestVM.QueryString += $"&actionType={actionType}";
                }
                #endregion

                return View(requestVM);
            }
            catch (Exception ex)
            {
                return View(new RequisitionStatusVM(){ErrorMessage = ex.Message.ToString()});
            }
        }

        public ActionResult ExpensesView(int requisitionID, string projectNo, string requisitionNo, string actionType)
        {
            #region Get the current logged-on user information
            int? userEmpNo = TempData["UserEmpNo"] != null ? _converter.ConvertObjectToInt(TempData.Peek("UserEmpNo")!) : 0;
            if (userEmpNo == 0)
            {
                // Initialize impersonator
                TempData["Impersonator"] = null;

                EmployeeInfo? empInfo = InitializeUserInfo();
                if (empInfo != null)
                {
                    // Define the session variables that will store the employee no. and cost center of the user
                    TempData["UserID"] = empInfo.UserID;
                    TempData["UserEmpNo"] = empInfo.EmpNo;
                    TempData["UserEmpName"] = empInfo.EmpName;
                    TempData["UserCostCenter"] = empInfo.CostCenter!;
                    TempData["ComputerName"] = Environment.MachineName.ToString();
                }
            }
            #endregion

            ExpenseVM expenseVM = new ExpenseVM()
            {
                ErrorMessage = string.Empty,
                NotificationMessage = string.Empty,
                RequisitionID = requisitionID,
                ProjectNo = projectNo,
                RequisitionNo = requisitionNo
            };

            // Save the caller form into the VM
            if (!string.IsNullOrEmpty(this.CallerForm))
            {
                expenseVM.CallerForm = this.CallerForm;
            }

            #region Set Query String
            if (!string.IsNullOrEmpty(requisitionNo))
            {
                expenseVM.QueryString = $"?requisitionNo={requisitionNo}";
            }

            if (!string.IsNullOrEmpty(actionType))
            {
                if (string.IsNullOrEmpty(expenseVM.QueryString))
                    expenseVM.QueryString = $"?actionType={actionType}";
                else
                    expenseVM.QueryString += $"&actionType={actionType}";
            }
            #endregion

            return View(expenseVM);
        }

        public async Task<ActionResult> EmployeeLookupView(string userCostCenter)
        {
            // Initialize model
            EmployeeVM empModel = new EmployeeVM()
            {
                ErrorMessage = string.Empty,
                NotificationMessage = string.Empty                
            };
            List<SelectListItem> costCenterArray = new List<SelectListItem>();

            try
            {
                #region Get the current logged-on user information
                int? userEmpNo = TempData["UserEmpNo"] != null ? _converter.ConvertObjectToInt(TempData.Peek("UserEmpNo")!) : 0;
                if (userEmpNo == 0)
                {
                    // Initialize impersonator
                    TempData["Impersonator"] = null;

                    EmployeeInfo? empInfo = InitializeUserInfo();
                    if (empInfo != null)
                    {
                        // Define the session variables that will store the employee no. and cost center of the user
                        TempData["UserID"] = empInfo.UserID;
                        TempData["UserEmpNo"] = empInfo.EmpNo;
                        TempData["UserEmpName"] = empInfo.EmpName;
                        TempData["UserCostCenter"] = empInfo.CostCenter!;
                        TempData["ComputerName"] = Environment.MachineName.ToString();
                    }
                }
                #endregion

                // Save the caller form into the VM
                if (!string.IsNullOrEmpty(this.CallerForm))
                    empModel.CallerForm = this.CallerForm;

                if (!string.IsNullOrEmpty(this.PreviousCallerForm))
                    empModel.PreviousCallerForm = this.PreviousCallerForm;

                #region Fetch data for cost center combobox
                var model = await _repository.GetLookupTable();
                if (model != null)
                {
                    if (model.CostCenterList != null)
                    {
                        // Populate Cost Center collection
                        foreach (var item in model.CostCenterList!)
                        {
                            costCenterArray.Add(new SelectListItem { Value = item.UDCValue, Text = HtmlEncoder.Default.Encode(item.UDCDescription) });
                        }
                    }
                }
                #endregion

                // Set other model properties
                empModel.CostCenter = userCostCenter;
                empModel.CostCenterArray = costCenterArray;
                empModel.ActionType = this.ActionType!;
                empModel.ProjectNo = this.ProjectNo;
            }
            catch (Exception ex)
            {
                empModel = new EmployeeVM()
                {
                    ErrorMessage = ex.Message.ToString()
                };
            }

            return View(empModel);
        }

        public async Task<IActionResult> CEARequisition(string requisitionNo)   
        {
            CEARequisitionVM ceaVM = new CEARequisitionVM()
            {
                ErrorMessage = string.Empty,
                NotificationMessage = string.Empty,
                FormCode = CEAFormCodes.CEAENTRY.ToString()
            };

            try
            {
                #region Get the current logged-on user information
                int? userEmpNo = TempData["UserEmpNo"] != null ? _converter.ConvertObjectToInt(TempData.Peek("UserEmpNo")!) : 0;
                if (userEmpNo == 0)
                {
                    // Initialize impersonator
                    TempData["Impersonator"] = null;

                    EmployeeInfo? empInfo = InitializeUserInfo();
                    if (empInfo != null)
                    {
                        // Define the session variables that will store the employee no. and cost center of the user
                        TempData["UserID"] = empInfo.UserID;
                        TempData["UserEmpNo"] = empInfo.EmpNo;
                        TempData["UserEmpName"] = empInfo.EmpName;
                        TempData["UserCostCenter"] = empInfo.CostCenter!;
                        TempData["ComputerName"] = Environment.MachineName.ToString();
                    }
                }
                #endregion

                GlobalSettings.ActionTypeOption actionType = GlobalSettings.ActionTypeOption.ReadOnly;
                CEARequest? requestData = null;
                string projectNo = !string.IsNullOrEmpty(this.ProjectNo) ? this.ProjectNo.Trim() : string.Empty;
                int? currentUserEmpNo = TempData["UserEmpNo"] != null ? _converter.ConvertObjectToInt(TempData.Peek("UserEmpNo")!) : 0;

                // Save the caller form into the VM
                if (!string.IsNullOrEmpty(this.CallerForm))
                {
                    ceaVM.CallerForm = this.CallerForm;
                }

                // Get the action type
                if (!string.IsNullOrEmpty(this.ActionType))
                {
                    actionType = (GlobalSettings.ActionTypeOption)Enum.Parse(typeof(GlobalSettings.ActionTypeOption), this.ActionType!);
                    //ceaVM.ActionType = actionType.ToString();

                    ceaVM.ActionType = this.ActionType;
                }

                if (actionType == ActionTypeOption.CreateNew)
                {
                    #region Create new request
                    ceaVM.ProjectNo = projectNo;

                    CEARequest ceaDetail = new CEARequest()
                    {
                        ProjectNo = projectNo,
                        RequisitionNo = String.Empty,
                        RequisitionID = 0,
                        OriginatorEmpNo = _converter.ConvertObjectToInt(this.CurrentUserEmpNo!) == 0 ? _converter.ConvertObjectToInt(TempData.Peek("UserEmpNo")!) : _converter.ConvertObjectToInt(this.CurrentUserEmpNo!),
                        OriginatorEmpName = string.IsNullOrEmpty(this.CurrentUserEmpName) ? _converter.ConvertObjectToString(TempData.Peek("UserEmpName")!) : this.CurrentUserEmpName!,
                        CreateDate = DateTime.Now,
                        CreatedByEmpNo = _converter.ConvertObjectToInt(this.CurrentUserEmpNo!) == 0 ? _converter.ConvertObjectToInt(TempData.Peek("UserEmpNo")!) : _converter.ConvertObjectToInt(this.CurrentUserEmpNo!),
                        CreatedByEmpName = string.IsNullOrEmpty(this.CurrentUserEmpName) ? _converter.ConvertObjectToString(TempData.Peek("UserEmpName")!) : this.CurrentUserEmpName!,
                        CreatedByUserID = _converter.ConvertObjectToString(TempData.Peek("UserID")!),
                        WorkstationID = _converter.ConvertObjectToString(TempData.Peek("ComputerName")!),
                        RequestDate = DateTime.Now,
                        DateofComission = DateTime.Now,
                        RequisitionStatus = "New Requisition",
                        IsDummy = true,
                        ExpenseJSON = "",
                        AttachmentJSON = ""
                    };

                    // Fetch project details from DB
                    ProjectInfo projectDetail = _repository.GetProjectDetail(projectNo.Trim());
                    if (projectDetail != null)
                    {
                        ceaDetail.Description = projectDetail.Description!;
                        ceaDetail.Reason = projectDetail.DetailDescription!;
                        ceaDetail.FiscalYear = projectDetail.FiscalYear;
                        ceaDetail.AccountNo = projectDetail.AccountNo!;
                        ceaDetail.ExpenditureTypeCode = projectDetail.ExpenditureTypeCode!;
                        ceaDetail.CostCenter = projectDetail.CostCenter!;
                        ceaDetail.ProjectAmount = projectDetail.ProjectAmount;
                        ceaDetail.UsedAmount = projectDetail.UsedAmount;
                        ceaDetail.ProjectBalanceAmt = _converter.ConvertObjectToDecimal(projectDetail.BalanceAmount!);
                        ceaDetail.AdditionalBudgetAmt = _converter.ConvertObjectToDecimal(projectDetail.AdditionalAmount!);
                    }

                    ceaVM.CEARequestDetail = ceaDetail;
                    #endregion
                }
                else if (actionType == ActionTypeOption.FetchEmployee)
                {
                    #region Process selected employee from Employee Lookup form
                    ceaVM.ProjectNo = projectNo;

                    CEARequest ceaDetail = new CEARequest()
                    {
                        ProjectNo = projectNo,
                        RequisitionNo = String.Empty,
                        RequisitionID = 0,
                        OriginatorEmpNo = _converter.ConvertObjectToInt(this.SearchEmpNo!), 
                        OriginatorEmpName = this.SearchEmpName!, 
                        CreateDate = DateTime.Now,
                        CreatedByEmpNo = _converter.ConvertObjectToInt(this.CurrentUserEmpNo!),
                        CreatedByEmpName = this.CurrentUserEmpName!,
                        RequestDate = DateTime.Now,
                        DateofComission = DateTime.Now,
                        RequisitionStatus = "New Requisition",
                        IsDummy = true
                    };

                    // Fetch project details from DB
                    ProjectInfo projectDetail = _repository.GetProjectDetail(projectNo.Trim());
                    if (projectDetail != null)
                    {
                        ceaDetail.Description = projectDetail.Description!;
                        ceaDetail.Reason = projectDetail.DetailDescription!;
                        ceaDetail.FiscalYear = projectDetail.FiscalYear;
                        ceaDetail.AccountNo = projectDetail.AccountCode!;
                        ceaDetail.ExpenditureTypeCode = projectDetail.ExpenditureTypeCode!;
                        ceaDetail.CostCenter = projectDetail.CostCenter!;
                        ceaDetail.ProjectAmount = projectDetail.ProjectAmount;
                        ceaDetail.UsedAmount = projectDetail.UsedAmount;
                        ceaDetail.ProjectBalanceAmt = _converter.ConvertObjectToDecimal(projectDetail.BalanceAmount!);
                        ceaDetail.AdditionalBudgetAmt = _converter.ConvertObjectToDecimal(projectDetail.AdditionalAmount!);
                    }

                    // Set the object collection
                    ceaVM.CEARequestDetail = ceaDetail;

                    // Get the selected employee
                    ceaVM.SearchEmpNo = this.SearchEmpNo;
                    ceaVM.SearchEmpName = this.SearchEmpName;

                    // Store the selected originator name to the session
                    TempData["SelectedOrigName"] = this.SearchEmpName;
                    #endregion
                }
                else if (actionType == ActionTypeOption.ShowReport)
                {
                    #region Download CEA report
                    string reportData = _converter.ConvertObjectToString(TempData["CEAReportData"]!);
                    if (!string.IsNullOrEmpty(reportData))
                    {
                        using (MemoryStream stream = new MemoryStream())
                        {
                            HtmlConverter.ConvertToPdf(reportData, stream);
                            return File(stream.ToArray(), "application/octet-stream", "Requisition.pdf");
                        }
                    }
                    #endregion
                }
                else if (actionType == ActionTypeOption.ForValidation)
                {
                    #region Open for validation
                    if (string.IsNullOrWhiteSpace(requisitionNo))
                        goto Exit_Here;

                    // Get the CEA Requisition details 
                    requestData = _repository.GetRequisitionDetail(requisitionNo);
                    if (requestData == null)
                    {
                        ceaVM.ErrorMessage = "No record found in the database.";
                        goto Exit_Here;
                    }
                    else
                    {
                        requestData.AdditionalBudgetAmtSync = requestData.AdditionalBudgetAmt;
                    }

                    // Store project detail into viewmodel
                    ceaVM.CEARequestDetail = requestData;
                    #endregion
                }
                else if (actionType == ActionTypeOption.Approval)
                {
                    #region Open for approval
                    if (string.IsNullOrWhiteSpace(requisitionNo))
                        goto Exit_Here;

                    // Get the CEA Requisition details 
                    requestData = _repository.GetRequisitionDetail(requisitionNo);
                    if (requestData == null)
                    {
                        ceaVM.ErrorMessage = "No record found in the database.";
                        goto Exit_Here;
                    }
                    else
                    {
                        // Set to read-only if current user is not the approver
                        //if (requestData.AssignedEmpNo > 0 && currentUserEmpNo > 0 && currentUserEmpNo != requestData.AssignedEmpNo)
                        //{
                        //    ceaVM.ActionType = GlobalSettings.ActionTypeOption.ReadOnly.ToString();
                        //}

                        requestData.AdditionalBudgetAmtSync = requestData.AdditionalBudgetAmt;
                    }

                    // Store project detail into viewmodel
                    ceaVM.CEARequestDetail = requestData;
                    #endregion
                }
                else 
                {
                    #region Show requisition details
                    if (string.IsNullOrWhiteSpace(requisitionNo))
                        goto Exit_Here;

                    // Get the CEA Requisition details 
                    requestData = _repository.GetRequisitionDetail(requisitionNo);
                    if (requestData == null)
                    {
                        ceaVM.ErrorMessage = "No record found in the database.";
                        goto Exit_Here;
                    }
                    else
                    {
                        requestData.AdditionalBudgetAmtSync = requestData.AdditionalBudgetAmt;
                    }

                    // Store project detail into viewmodel
                    ceaVM.CEARequestDetail = requestData;
                    #endregion
                }

                #region Initialize lookup data                
                List<SelectListItem> costCenterArray = new List<SelectListItem>();
                List<SelectListItem> fiscalYearArray = new List<SelectListItem>();
                List<SelectListItem> itemTypeArray = new List<SelectListItem>();
                List<SelectListItem> expenditureTypeArray = new List<SelectListItem>();
                List<SelectListItem> plantLocationArray = new List<SelectListItem>();
                List<SelectListItem> expenseYearArray = new List<SelectListItem>();
                List<SelectListItem> expenseQuarterArray = new List<SelectListItem>();
                List<EmployeeDetail> ceaAdminArray = new List<EmployeeDetail>();

                var model = await _repository.GetLookupTable(LookupTableType.CEAREQUISITION.ToString());
                if (model != null)
                {
                    if (model.CostCenterList != null)
                    {
                        // Populate Cost Center 
                        foreach (var item in model.CostCenterList!)
                        {
                            costCenterArray.Add(new SelectListItem { Value = item.UDCValue, Text = HtmlEncoder.Default.Encode(item.UDCDescription) });
                        }
                    }

                    // Populate Fiscal Year 
                    if (model.FiscalYearList != null)
                    {
                        foreach (var item in model.FiscalYearList!)
                        {
                            fiscalYearArray.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                        }
                    }

                    // Populate Item Types 
                    if (model.ItemTypeList != null)
                    {
                        foreach (var item in model.ItemTypeList!)
                        {
                            itemTypeArray.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                        }
                    }

                    // Populate Expenditure Types 
                    if (model.ExpenditureTypeList != null)
                    {
                        foreach (var item in model.ExpenditureTypeList!)
                        {
                            expenditureTypeArray.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                        }
                    }

                    // Populate Plant Locations
                    if (model.PlantLocationList != null)
                    {
                        foreach (var item in model.PlantLocationList!)
                        {
                            plantLocationArray.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                        }
                    }

                    // Populate Schedule of Expense - Year
                    if (model.ExpenseYearList != null)
                    {
                        foreach (var item in model.ExpenseYearList!)
                        {
                            expenseYearArray.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                        }
                    }

                    // Populate Schedule of Expense - Quarter
                    if (model.ExpenseQuarterList != null)
                    {
                        foreach (var item in model.ExpenseQuarterList!)
                        {
                            expenseQuarterArray.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                        }
                    }

                    // Populate CEA Administrators
                    if (model.CEAAdminList != null)
                    {
                        foreach (var item in model.CEAAdminList!)
                        {
                            ceaAdminArray.Add(new EmployeeDetail { empNo = item.empNo, empName = item.empName });
                        }
                    }
                }

                // Store collections into viewmodel
                ceaVM.CostCenterList = costCenterArray;
                ceaVM.FiscalYearList = fiscalYearArray;
                ceaVM.ItemTypeList = itemTypeArray;
                ceaVM.ExpenditureTypeList = expenditureTypeArray;
                ceaVM.PlantLocationList = plantLocationArray;
                ceaVM.ExpenseYearList = expenseYearArray;
                ceaVM.ExpenseQuarterList = expenseQuarterArray;
                ceaVM.CEAAdminList = ceaAdminArray;
                #endregion

            Exit_Here:
                return View(ceaVM);
            }
            catch (Exception ex)
            {
                ceaVM = new CEARequisitionVM()
                {
                    ErrorMessage = ex.Message.ToString()
                };
            }

            return View(ceaVM);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CEARequisition([Bind("RequisitionNo,RequisitionID,ProjectNo,CostCenter,RequestDate,OriginatorEmpNo,PlantLocationID,CategoryCode1,EstimatedLifeSpan,Description,Reason,DateofComission,RequestedAmt,AdditionalBudgetAmtSync,RequisitionDescription,ReasonForAdditionalAmt,FiscalYear,EquipmentNo,EquipmentParentNo,CreatedByEmpName,CreatedByEmpNo,MultipleItems,ExpenseJSON,AttachmentJSON,IsDraft,ButtonActionType")] CEARequest requestData)
        {
            CEARequisitionVM ceaVM = new CEARequisitionVM()
            {
                ErrorMessage = string.Empty,
                NotificationMessage = string.Empty
            };

            #region Validate submitted data
            if (string.IsNullOrWhiteSpace(requestData.ReasonForAdditionalAmt))
                requestData.ReasonForAdditionalAmt = String.Empty;

            if (string.IsNullOrWhiteSpace(requestData.EquipmentNo))
                requestData.EquipmentNo = String.Empty;

            if (string.IsNullOrWhiteSpace(requestData.EquipmentParentNo))
                requestData.EquipmentParentNo = String.Empty;

            if (string.IsNullOrWhiteSpace(requestData.PlantLocationID))
                requestData.PlantLocationID = String.Empty;

            if (requestData.CreatedByEmpNo == 0)
            {
                requestData.CreatedByEmpNo = TempData["UserEmpNo"] != null ? _converter.ConvertObjectToInt(TempData.Peek("UserEmpNo")!) : 0; 
                if (requestData.CreatedByEmpNo == 0)
                {
                    EmployeeInfo? empInfo = InitializeUserInfo();
                    if (empInfo != null)
                    {
                        TempData["UserID"] = empInfo.UserID;
                        TempData["UserEmpNo"] = empInfo.EmpNo;
                        TempData["UserEmpName"] = empInfo.EmpName;
                        TempData["UserCostCenter"] = empInfo.CostCenter!;
                        TempData["ComputerName"] = Environment.MachineName.ToString();
                    }
                }
            }

            if (string.IsNullOrEmpty(requestData.CreatedByEmpName))
                requestData.CreatedByEmpName = TempData["UserEmpName"] != null ? _converter.ConvertObjectToString(TempData.Peek("UserEmpName")!) : string.Empty;

            #endregion

            // Get the schedule of expenses
            if (!string.IsNullOrEmpty(requestData.ExpenseJSON))
            {

                requestData.ScheduleExpenseList = JsonConvert.DeserializeObject<List<FinancialDetail>>(requestData.ExpenseJSON!);
            }

            // Get the attachments
            if (!string.IsNullOrEmpty(requestData.AttachmentJSON))
            {
                requestData.AttachmentList = JsonConvert.DeserializeObject<List<FileAttachment>>(requestData.AttachmentJSON!);
            }

            ProjectRepository.DataAccessType dbActionType = ProjectRepository.DataAccessType.Create;
            if (requestData.ButtonActionType == Convert.ToInt32(ButtonAction.Delete))
            {
                dbActionType = ProjectRepository.DataAccessType.Delete;
            }
            else
            {
                if (!string.IsNullOrEmpty(requestData.RequisitionNo))
                    dbActionType = ProjectRepository.DataAccessType.Update;
            }

            // Get the user id of the current user
            if (string.IsNullOrEmpty(requestData.CreatedByUserID))
                requestData.CreatedByUserID = _converter.ConvertObjectToString(TempData.Peek("UserID")!);

            // Get the user's computer name
            if (string.IsNullOrEmpty(requestData.WorkstationID))
                requestData.WorkstationID = _converter.ConvertObjectToString(TempData.Peek("ComputerName")!);

            // Save to database
            DBTransResult? dbResult = await _repository.InsertUpdateDeleteRequisition(dbActionType, requestData);
            if (dbResult != null && dbResult.HasError)
            {
                ceaVM.ErrorMessage = dbResult.ErrorDesc;
                return RedirectToAction(nameof(CEARequisition), new
                {
                    projectNo = requestData.ProjectNo,
                    requisitionNo = dbActionType == ProjectRepository.DataAccessType.Create ? dbResult.CEANo : requestData.RequisitionNo,
                    actionType = requestData.IsDraft ? Convert.ToInt32(GlobalSettings.ActionTypeOption.Draft).ToString() : Convert.ToInt32(GlobalSettings.ActionTypeOption.ReadOnly).ToString()
                });
            }
            else
            {
                string requisitionNo = dbActionType == ProjectRepository.DataAccessType.Create ? dbResult!.CEANo : requestData.RequisitionNo;

                // Set session data 
                TempData["InvokeSearch"] = 1;
                TempData["IgnoreSavedData"] = 1;

                if (requestData.ButtonActionType == Convert.ToInt32(ButtonAction.Draft))
                    TempData["ToastNotification"] = "Requisition No. " + requisitionNo + " has been saved successfully as a draft.";
                else if (requestData.ButtonActionType == Convert.ToInt32(ButtonAction.Submit))
                    TempData["ToastNotification"] = "Requisition No. " + requisitionNo + " has been submitted successfully.";

                return RedirectToAction(nameof(RequisitionInquiry), new
                {
                    filterFiscalYear = requestData.FiscalYear,
                    filterCostCenter = requestData.CostCenter
                    //filterCEANo = requisitionNo
                });
            }
        }

        public void DownloadFileAttachment()
        {
            try
            {
                
                //FileInfo file = new FileInfo(fullPath);
                //if (file.Exists)
                //{
                    
                //    Response.Clear();
                //    Response.ClearHeaders();
                //    Response.ClearContent();
                //    Response.AddHeader("Content-Disposition", "attachment; filename=" + file.Name);
                //    Response.AddHeader("Content-Length", file.Length.ToString());
                //    Response.ContentType = GAPFunction.GetMimeType(file.Name);
                //    Response.Flush();
                //    Response.TransmitFile(file.FullName);
                //    Response.End();
                //}
                //else
                //    Response.Write("This file does not exist!");
            }
            catch (Exception)
            {

                throw;
            }
        }
        #endregion

        #region Database Access 
        /// <summary>
        /// This method is used to fetch the list of projects from the database
        /// </summary>
        /// <param name="fiscalYear"></param>
        /// <param name="projectNo"></param>
        /// <param name="costCenter"></param>
        /// <param name="expenditureType"></param>
        /// <param name="statusCode"></param>
        /// <param name="keywords"></param>
        /// <returns></returns>
        public ActionResult LoadProjectList(int fiscalYear, string projectNo, string costCenter, string expenditureType, string statusCode, string keywords)
        {
            try
            {
                // Fetch database records
                var model = _repository.GetProjectList(fiscalYear, projectNo, costCenter, expenditureType, statusCode, keywords);

                // Convert data to Json
                return Json(new { data = model });
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        public async Task<ActionResult> LoadRequisitionList(string projectNo, string requisitionNo, string expenditureType, int fiscalYear, string statusCode, string costCenter, int empNo, string approvalType,
            string keywords, string startDate, string endDate, int otherEmpNo, byte createdByType)
        {
            try
            {
                DateTime? sDate = _converter.ConvertObjectToDate(startDate);
                DateTime? eDate = _converter.ConvertObjectToDate(endDate);

                int filterEmpNo = 0;
                if (!string.IsNullOrWhiteSpace(approvalType))
                {
                    #region Get the assignee employee
                    SearchRequisitionType searchType = (SearchRequisitionType)Enum.Parse(typeof(SearchRequisitionType), approvalType);
                    switch (searchType)
                    {
                        case SearchRequisitionType.ASGNTOME:
                            filterEmpNo = empNo;
                            break;

                        case SearchRequisitionType.ASGNTOOTHR:
                            filterEmpNo = otherEmpNo;
                            break;
                    }
                    #endregion
                }
                else
                    filterEmpNo = empNo;

                // Fetch database records
                var model = await _repository.GetRequisitionListNew(projectNo, requisitionNo, expenditureType, fiscalYear, statusCode, costCenter, 
                    filterEmpNo, approvalType, keywords, sDate, eDate, createdByType);

                // Convert data to Json
                return Json(new { data = model });
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        /// <summary>
        /// This method is used to fetch the list of all active employees from JDE
        /// </summary>
        /// <param name="empNo"></param>
        /// <returns></returns>
        public ActionResult GetEmployeeList(int empNo)
        {
            try
            {
                // Fetch database records
                var model = _repository.GetEmployeeList(empNo);

                // Convert data to Json
                return Json(new { data = model });
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        public async Task<ActionResult> GetRequisitionStatusTable(int requisitionID)
        {
            try
            {
                // Fetch database records
                var model = await _repository.GetRequisitionStatus(requisitionID);

                // Convert data to Json
                return Json(new { data = model });

            }
            catch (Exception ex)
            {
                return null;
            }
        }

        public async Task<ActionResult> GetWorkflowStatusTable(string ceaNo)
        {
            try
            {
                // Fetch database records
                var model = await _repository.GetWorkflowStatus(ceaNo);

                // Convert data to Json
                return Json(new { data = model });

            }
            catch (Exception ex)
            {
                return null;
            }
        }


        public async Task<ActionResult> GetExpenseTable(string requisitionNo)
        {
            try
            {
                // Fetch database records
                var model = await _repository.GetExpenseList(requisitionNo);

                TempData["ExpenseListCount"] = model.Count();

                // Convert data to Json
                return Json(new { data = model });

            }
            catch (Exception ex)
            {
                return null;
            }
        }

        public ActionResult GetEmployeeTable(int? empNo, string? empName, string? costCenter)
        {
            try
            {
                // Fetch database records
                var model = _repository.SearchEmployee(empNo, empName, costCenter);

                // Store record count to session
                TempData["EmployeeListCount"] = model.Count();

                // Convert data to Json
                return Json(new { data = model });

            }
            catch (Exception ex)
            {
                return null;
            }
        }

        /// <summary>
        /// This method is used to fetch all equipments from JDE
        /// </summary>
        /// <returns></returns>
        public ActionResult GetEquipmentList()
        {
            try
            {
                // Fetch database records
                var model = _repository.GetEquipmentList();

                // Convert data to Json
                return Json(new { data = model });
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        /// <summary>
        /// This method is used to recall, reactivate, and reopen a CEA requisition
        /// </summary>
        /// <returns></returns>
        public async Task<ActionResult> ChangeRequisitionStatus(string requisitionNo, string actionType, int empNo, string comments, string wfInstanceID)
        {
            try
            {
                int cancelledBy = _converter.ConvertObjectToInt(TempData.Peek("UserEmpNo")!);
                string cancelledByName = _converter.ConvertObjectToString(TempData.Peek("UserEmpName")!);

                // Save to database
                var model = await _repository.ChangeRequisitionStatus(requisitionNo, actionType, empNo, comments, cancelledByName, wfInstanceID);

                // Convert data to Json
                return Json(new { data = model });
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        /// <summary>
        /// This method is used to recall, reactivate, and reopen a CEA requisition
        /// </summary>
        /// <returns></returns>
        public async Task<ActionResult> ReassignRequisition(string requisitionNo, int currentAssignedEmpNo, int reassignedEmpNo, string reassignedEmpName, string reassignedEmpEmail,
            int routineSeq, bool onHold, string reason, string wfInstanceID, int reassignedBy, string reassignedName, string ceaDescription)
        {
            try
            {
                //int reassignedBy = _converter.ConvertObjectToInt(TempData.Peek("UserEmpNo")!);
                //string reassignedName = _converter.ConvertObjectToString(TempData.Peek("UserEmpName")!);

                string reassignRemark = string.Format("{0}|{1}", reassignedBy, reason);

                // Save to database
                var model = await _repository.ReassignRequest(requisitionNo, currentAssignedEmpNo, reassignedEmpNo, reassignedEmpName, reassignedEmpEmail,
                    routineSeq, onHold, reassignRemark, reassignedBy, reassignedName, wfInstanceID, ceaDescription);

                // Convert data to Json
                return Json(new { data = model });
            }
            catch (Exception ex)
            {
                return null;
            }
        }
        #endregion

        #region Security Methods
        private EmployeeInfo? InitializeUserInfo()
        {
            EmployeeInfo? empInfo = null;

            try
            {
                string currentImpersonator = TempData["Impersonator"] != null ? _converter.ConvertObjectToString(TempData.Peek("Impersonator")!) : string.Empty;
                string? userID = TempData["UserID"] != null ? _converter.ConvertObjectToString(TempData.Peek("UserID")!) : HttpContext.User.Identity!.Name;

                if (!string.IsNullOrEmpty(userID))
                {
                    empInfo = _securityController.GetUserCredentialWithImpersonation(userID, ref currentImpersonator);

                    if (!string.IsNullOrEmpty(currentImpersonator))
                        TempData["Impersonator"] = currentImpersonator;
                }

                return empInfo;
            }
            catch (Exception)
            {
                return null;
            }
        }
        #endregion

        #region Workflow Methods
        public ActionResult ApproveRejectRequest(string requisitionNo, string wfInstanceID, int appRole, int appRoutineSeq, bool appApproved, string appRemarks, int approvedBy, string approvedName, string statusCode)
        {
            try
            {
                // Save to database
                var model = _repository.ApproveRejectRequest(requisitionNo, wfInstanceID, appRole, appRoutineSeq, appApproved, appRemarks, approvedBy, approvedName, statusCode);

                // Convert data to Json
                return Json(new { data = model });
            }
            catch (Exception ex)
            {
                return null;
            }
        }
        #endregion
    }
}
