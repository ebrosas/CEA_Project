using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using CEAApp.Web.Models;
using CEAApp.Web.ViewModels;
using CEAApp.Web.Repositories;
using CEAApp.Web.Helpers;
using Microsoft.AspNetCore.Mvc.Rendering;
using System.Collections.ObjectModel;
using CEAApp.Web.DIServices;
using System.Net.Http.Headers;
using Newtonsoft.Json;
using System.Data;
using System.Net;
using static CEAApp.Web.Models.GlobalSettings;
using CEAApp.Web.Areas.UserFunctions.Controllers;
using iText.Forms.Form.Element;
using iText.Layout.Element;
using System.Text;
using System.Text.Encodings.Web;
using static System.Net.WebRequestMethods;

namespace CEAApp.Web.Areas.AdminFunctions.Controllers
{
    [Area("AdminFunctions")]
    public class AdminController : Controller
    {
        #region Members
        private readonly IRequisitionRepository _repository;
        private readonly IExcelUploadRepository _excelUploadrepository;
        private readonly IConfiguration _config;
        private readonly IConverterService _converter;
        private readonly SecurityController _securityController;
        private readonly EmailCommunications _emailCom;
        private readonly IProjectRepository _projectRepository;
        public string? ToastNotification { get; set; }
        private int defaultFiscalYear = DateTime.Now.Year;
        #endregion

        public AdminController(IRequisitionRepository repository, IExcelUploadRepository excelUploadrepository, IConfiguration configuration, IConverterService converter, SecurityController securityController, EmailCommunications emailCom, IProjectRepository projectRepository)
        {
            _repository = repository;
            _excelUploadrepository = excelUploadrepository;
            _config = configuration;
            _converter = converter;
            _securityController = securityController;
            _emailCom = emailCom;
            _projectRepository = projectRepository;
        }

        public IActionResult Index()
        {
            return View();
        }

        public async Task<IActionResult> RequisitionAdmin()
        {
            RequisitionVM? requisitionVM = null;
            try
            {
                List<SelectListItem> fiscalYearArray = new List<SelectListItem>();
                List<SelectListItem> costCenterArray = new List<SelectListItem>();
                List<SelectListItem> projectStatusArray = new List<SelectListItem>();
                List<SelectListItem> expenditureTypeArray = new List<SelectListItem>();
                List<SelectListItem> requisitionStatusArray = new List<SelectListItem>();
               
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
                            costCenterArray.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
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
                        // Populate Project Status collection
                        foreach (var item in model.RequisitionStatusList!)
                        {
                            requisitionStatusArray.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                        }
                    }
                }

                // Initialize the model to be returned to the view
                requisitionVM = new RequisitionVM()
                {
                    FiscalYearArray = fiscalYearArray,
                    CostCenterArray = costCenterArray,
                    ProjectStatusArray = projectStatusArray,
                    ExpenditureTypeArray = expenditureTypeArray,
                    RequisitionStatusArray = requisitionStatusArray,
                    FormCode = CEAFormCodes.REQUESTADM.ToString(),
                    FiscalYear = defaultFiscalYear.ToString(),
                    RequisitionStatus = GlobalSettings.CEAStatusCode.Approved.ToString(),
                    ErrorMessage = TempData["UploadErrorMessage"] != null? TempData["UploadErrorMessage"]!.ToString() : string.Empty,
            };

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
                    }
                }
                #endregion
            }
            catch (Exception ex)
            {
                requisitionVM = new RequisitionVM()
                {
                    ErrorMessage = ex.Message.ToString()
                };
            }

            return View(requisitionVM);
        }

        public async Task<IActionResult> LoadRequisition(string costCenter, string expenditureType, int? fiscalYear, string projectNo, string requisitionStatus, int requisitionNo, string keywords)
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
                    }
                }
                #endregion
                var model = _repository.LoadRequisitionAsync(costCenter, expenditureType, fiscalYear, projectNo, requisitionStatus, requisitionNo, keywords, false, 0);
                return Json(new { data = model });
            }
            catch (Exception ex)
            {
                throw new Exception(ex.GetBaseException().Message, ex.GetBaseException());
            }
        }

        public async Task<IActionResult> ManageEquipmentNo(string id)
        {
            RequisitionVM? requisitionVM = null;
            try
            {
                // Initialize the model to be returned to the view
                //requisitionVM = new RequisitionVM();
                //requisitionVM.FormCode = CEAFormCodes.EQUIPTASGN.ToString();

                List<SelectListItem> fiscalYearArray = new List<SelectListItem>();
                List<SelectListItem> costCenterArray = new List<SelectListItem>();
                List<SelectListItem> expenditureTypeArray = new List<SelectListItem>();

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
                            costCenterArray.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
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
                }

                // Get session data
                string? toastNotification = TempData["ToastNotification"] != null ? _converter.ConvertObjectToString(TempData["ToastNotification"]!)
                    : !string.IsNullOrEmpty(this.ToastNotification) ? this.ToastNotification : null;


                //// Initialize the model to be returned to the view
                requisitionVM = new RequisitionVM()
                {
                    FiscalYearArray = fiscalYearArray,
                    CostCenterArray = costCenterArray,
                    ExpenditureTypeArray = expenditureTypeArray,
                    FormCode = CEAFormCodes.EQUIPTASGN.ToString(),
                    ToastNotification = toastNotification,
                    FiscalYear = defaultFiscalYear.ToString(),
                };

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
                    }
                }
                #endregion

            }
            catch (Exception ex)
            {
                requisitionVM = new RequisitionVM()
                {
                    ErrorMessage = ex.Message.ToString()
                };
            }

            return View(requisitionVM);
        }

        public async Task<IActionResult> LoadManageEquipmentNo(string costCenter, string expenditureType, string projectNo, int requisitionNo, int fromFiscalYear, int toFiscalYear)
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
                    }
                }
                #endregion
                await Task.Yield();
                var model = _repository.LoadRequisitionAssignmentAsync(costCenter, expenditureType, projectNo, requisitionNo, fromFiscalYear, toFiscalYear);

                //var model = _repository.LoadRequisitionAsync(costCenter, expenditureType, fromFiscalYear, projectNo, requisitionStatus, requisitionNo, keywords, false, 0);
                return Json(new { data = model });
            }
            catch (Exception ex)
            {
                throw new Exception(ex.GetBaseException().Message, ex.GetBaseException());
            }
        }


        public async Task<IActionResult> ManageEquipmentNoEdit(int id, Requisition _requisition)
        {
            RequisitionVM? requisitionVM = null;
            try
            {
                string CostCenter = "", ExpenditureType = "", ProjectNo = "";
                int RequisitionNo = id;
                int FromFiscalYear = 0, ToFiscalYear = 0;
                var model = _repository.LoadRequisitionAssignmentAsync(CostCenter, ExpenditureType, ProjectNo, RequisitionNo, FromFiscalYear, ToFiscalYear);

                if (model != null)
                {
                    _requisition.RequisitionNo = model.Result[model.Result.Count - 1].RequisitionNo;
                    _requisition.Reason = model.Result[model.Result.Count - 1].Reason;
                    _requisition.Description = model.Result[model.Result.Count - 1].Description;
                    _requisition.EstimatedLifeSpan = model.Result[model.Result.Count - 1].EstimatedLifeSpan;
                    _requisition.RequestedAmt = model.Result[model.Result.Count - 1].RequestedAmt;
                    _requisition.AccountNo = model.Result[model.Result.Count - 1].AccountNo;

                    _requisition.EquipmentNo = model.Result[model.Result.Count - 1].EquipmentNo;
                    _requisition.EquipmentParentNo = model.Result[model.Result.Count - 1].EquipmentParentNo;
                    _requisition.EquipmentDescription = model.Result[model.Result.Count - 1].EquipmentDescription;
                    _requisition.EquipmentParentDescription = model.Result[model.Result.Count - 1].EquipmentParentDescription;
                }

                // Initialize the model to be returned to the view
                requisitionVM = new RequisitionVM()
                {
                    requisition = _requisition,
                    disableElements = true,
                };

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
                    }
                }
                #endregion
                return View(requisitionVM);
            }
            catch (Exception ex)
            {
                requisitionVM = new RequisitionVM()
                {
                    ErrorMessage = ex.Message.ToString()
                };
            }

            return View(requisitionVM);
        }

        public async Task<IActionResult> LoadEquipmentNo(Requisition _requisition)
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
                    }
                }
                #endregion
                await Task.Yield();
                var model = _repository.LoadEquipmentNoAsync(_requisition.RequisitionNo = "0");
                return Json(new { data = model });
            }
            catch (Exception ex)
            {
                throw new Exception(ex.GetBaseException().Message, ex.GetBaseException());
            }
        }

        public async Task<IActionResult> SaveEquipmentNo(string RequisitionNo, string EquipmentNo, string ParentEquipmentNo, string IsEquipmentNoRequired)
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
                    }
                }
                #endregion
                ParentEquipmentNo = ParentEquipmentNo ?? "0";
                //Save to database
                DBTransResult? dbResult = await _repository.SaveEquipmentNoAsync(RequisitionNo, EquipmentNo, ParentEquipmentNo, IsEquipmentNoRequired);

                ////return RedirectToAction("ManageEquipmentNo");
                //return RedirectToAction(actionName: "ManageEquipmentNo", controllerName: "Admin", new { area = "AdminFunctions" });

                if (dbResult.RowsAffected == 1)
                {
                    return Json(new { status = "success" });

                    //// Display successful notification
                    //TempData["ToastNotification"] = "Equipment No. have been updated successfully!";

                    ////return RedirectToAction("ManageEquipmentNo", "Admin", new{ Id = 0 });
                    //return RedirectToAction("ManageEquipmentNo", "Admin", new
                    //{
                    //    area = "AdminFunctions",
                    //    Id = 0,
                    //    actionType = 9966,
                    //    callerForm = "ManageEquipmentNoEdit"
                    //});
                }
                else
                {
                    return Json(new { status = "error" });
                }
            }
            catch (Exception ex)
            {
                throw new Exception(ex.GetBaseException().Message, ex.GetBaseException());
            }
        }

        [HttpPost, ValidateAntiForgeryToken]
        public async Task<IActionResult> SaveFormEquipmentNo()
        {
            try
            {

                string RequisitionNo = HttpContext.Request.Form["txtRequisitionNo"]!;
                string EquipmentNo = HttpContext.Request.Form["txtEquipmentNo"]!;
                string ParentEquipmentNo = HttpContext.Request.Form["txtEquipmentParentNo"]!;
                string IsEquipmentNoRequired = HttpContext.Request.Form["chkEquipmentNoRequired"]!;

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
                    }
                }
                #endregion
                ParentEquipmentNo = ParentEquipmentNo ?? "0";
                //Save to database
                DBTransResult? dbResult = await _repository.SaveEquipmentNoAsync(RequisitionNo, EquipmentNo, ParentEquipmentNo, IsEquipmentNoRequired);

                ////return RedirectToAction("ManageEquipmentNo");
                //return RedirectToAction(actionName: "ManageEquipmentNo", controllerName: "Admin", new { area = "AdminFunctions" });

                if (dbResult.RowsAffected == 1)
                {
                    // Display successful notification
                    TempData["ToastNotification"] = "Equipment No. have been updated successfully!";

                    //return RedirectToAction("ManageEquipmentNo", "Admin", new{ Id = 0 });
                    return RedirectToAction("ManageEquipmentNo", "Admin", new
                    {
                        area = "AdminFunctions",
                        Id = 0,
                        actionType = 0,
                        callerForm = "ManageEquipmentNoEdit"
                    });
                }
                else
                {
                    return Json(new { status = "error" });
                }
            }
            catch (Exception ex)
            {
                throw new Exception(ex.GetBaseException().Message, ex.GetBaseException());
            }
        }

        //project data upload
        [HttpGet]
        public async Task<IActionResult> UploadProject([FromQuery(Name = "UpldProjectFile")] string UpldProjectFile)
        {

            RequisitionVM? requisitionVM = null;
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
                    }
                }
                #endregion
                await Task.Yield();
                // Initialize the model to be returned to the view
                requisitionVM = new RequisitionVM();
                ViewBag.FormCode = CEAFormCodes.PROJCTUPLD.ToString();

                return View();
            }
            catch (Exception ex)
            {
                requisitionVM = new RequisitionVM()
                {
                    ErrorMessage = ex.Message.ToString()
                };
                return View(requisitionVM);
            }
        }

        [HttpPost]
        public async Task<IActionResult> FileUpload(IFormFile file)
        {
            try
            {
                await Task.Yield();
                #region Get the current logged-on user information
                int? userEmpNo = TempData["UserEmpNo"] != null ? _converter.ConvertObjectToInt(TempData.Peek("UserEmpNo")!) : 0;
                EmployeeInfo? empInfo = InitializeUserInfo();
                if (userEmpNo == 0)
                {
                    // Initialize impersonator
                    TempData["Impersonator"] = null;

                   
                    if (empInfo != null)
                    {
                        // Define the session variables that will store the employee no. and cost center of the user
                        TempData["UserID"] = empInfo.UserID;
                        TempData["UserEmpNo"] = empInfo.EmpNo;
                        TempData["UserEmpName"] = empInfo.EmpName;
                        TempData["UserCostCenter"] = empInfo.CostCenter!;
                    }
                }
                #endregion
                ExcelDataUpload excelData = new ExcelDataUpload(_converter);

                // read the data fom excel
                List<Project> model = excelData.ReadFromExcel(file, empInfo);
                return Json(new { data = model });
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        // Save uploaded file data
        public async Task<IActionResult> SaveExcel(IFormFile file, string UserName)
        {
            try
            {
                #region Get the current logged-on user information
                int? userEmpNo = TempData["UserEmpNo"] != null ? _converter.ConvertObjectToInt(TempData.Peek("UserEmpNo")!) : 0;
                EmployeeInfo? empInfo = InitializeUserInfo();
                if (userEmpNo == 0)
                {
                    // Initialize impersonator
                    TempData["Impersonator"] = null;

                    if (empInfo != null)
                    {
                        // Define the session variables that will store the employee no. and cost center of the user
                        TempData["UserID"] = empInfo.UserID;
                        TempData["UserEmpNo"] = empInfo.EmpNo;
                        TempData["UserEmpName"] = empInfo.EmpName;
                        TempData["UserCostCenter"] = empInfo.CostCenter!;
                    }
                }
                #endregion
                await Task.Yield();
                var retVal = _excelUploadrepository.SaveFromExcel(file, empInfo);
                //return RedirectToAction(actionName: "UploadProject", controllerName: "Admin", new { area = "AdminFunctions" });
                return Json(new { data = retVal });
            }
            catch (Exception ex)
            {
                throw new Exception(ex.GetBaseException().Message, ex.GetBaseException());
            }
        }

        public IActionResult UploadToOneWorld(int requisitionID, int requisitionNo, int companyCode, string costCenter, string objectCode, string subjectCode, string accountCode, string requisitionAmount, string status, string userID)
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
                }
            }
            #endregion
            userID = Convert.ToString(TempData["UserID"]);
            string UserEmpNo = Convert.ToString(TempData["UserEmpNo"]);
            string ip = Response.HttpContext.Connection.RemoteIpAddress.ToString();
            string workstationID;

            IPHostEntry host = Dns.GetHostByName(Dns.GetHostEntry(HttpContext.Connection.RemoteIpAddress).HostName);
            if (host.HostName.LastIndexOf(".") > 0)
            { workstationID = host.HostName.ToString().Substring(0, host.HostName.IndexOf(".")); }
            else
            { workstationID = host.HostName; }

            try
            {
                // Accesing RequisitionStatusCode enum variable
                RequisitionStatusCode RequestStatus = (RequisitionStatusCode)Enum.Parse(typeof(RequisitionStatusCode), status);

                string checkStatus = string.Empty;
                if (RequestStatus == RequisitionStatusCode.AwaitingChairmanApproval)
                {
                    checkStatus = "Chairman Approved";
                }
                else if (RequestStatus == RequisitionStatusCode.Approved)
                {
                    checkStatus = "Upload to OneWorld";
                }
                else if (RequestStatus == RequisitionStatusCode.UploadedToOneWorld)
                {
                    checkStatus = "Close Requisition";
                }

                switch (checkStatus)
                {

                    case "Chairman Approved":
                        int requestNo = requisitionNo;
                        return RedirectToAction("CEARequisition", "Project", new
                        {
                            area = "UserFunctions",
                            requisitionNo = requestNo,
                            actionType = "Approval",
                            callerForm = "UploadToOneWorld"
                        });

                    case "Upload to OneWorld":
                        var retVal = _repository.UploadToOneWorld(requisitionID, companyCode, costCenter, objectCode, subjectCode, accountCode, requisitionAmount, userID, workstationID).Result;
                        string? statusCode;
                        if (retVal == 1)
                        {
                            statusCode = Enum.Parse(typeof(RequisitionStatusCode), "UploadedToOneWorld").ToString();
                            _repository.UpdateRequisitionStatus(statusCode, requisitionID, UserEmpNo, "Requisition uploaded to OneWorld.");

                            // Get Approvers list
                            List<ApproversDetails> approversDetailslist = _repository.LoadApproversDetailsAsync(requisitionID).Result;

                            //send notification to the cost center users- secretary, originator, manager etc. informing the Requisition is approved
                            foreach (var approver in approversDetailslist)
                            {
                                string subject = "CEA/MRE Requisition # " + requisitionNo + " - Status Notification.";
                                string mailbody = _emailCom.UploadToOneWorldMailBody(approver);

                                // Format the message contents
                                string htmLBody = string.Format("<HTML><BODY><p>{0}</p></BODY></HTML>", mailbody);

                                _emailCom.SendEmailToApprovers(subject, mailbody, approver);                              
                            }

                            return Json(new { status = "success" });
                        }
                        break;

                    case "Close Requisition":
                        if (_repository.CloseRequisitionUpdationToOneWorld(requisitionID).Result)
                        {
                            statusCode = Enum.Parse(typeof(RequisitionStatusCode), "Closed").ToString();
                            _repository.UpdateRequisitionStatus(statusCode, requisitionID, UserEmpNo, "Requisition closed.");
                            return Json(new { status = "success" });
                        }

                        break;
                }
                return RedirectToAction("RequisitionAdmin", "Admin");
            }
            catch (Exception ex)
            {
                //throw new Exception(ex.GetBaseException().Message, ex.GetBaseException());

                //RequisitionVM? requisitionVM = null;
                //requisitionVM = new RequisitionVM()
                //{
                //    ErrorMessage = ex.Message.ToString()
                //};

                TempData["UploadErrorMessage"] = ex.Message.ToString();

                return RedirectToAction("RequisitionAdmin", "Admin");
            }

            return View();
        }

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

        public async Task<IActionResult> Reassignment()
        {
            try
            {
                Reassignment _reassignment = new Reassignment();
                List<SelectListItem> _fiscalYearList = new List<SelectListItem>();
                List<SelectListItem> _costCenterList = new List<SelectListItem>();
                List<SelectListItem> _expenditureTypeList = new List<SelectListItem>();

                var model = await _repository.GetLookupTable();
                if (model != null)
                {
                    // Populate Fiscal Year collection
                    if (model.FiscalYearList != null)
                    {
                        foreach (var item in model.FiscalYearList!)
                        {
                            _fiscalYearList.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                        }
                        if (_fiscalYearList.Where(o => Convert.ToInt32(o.Value) == defaultFiscalYear).FirstOrDefault() == null)
                        {
                            defaultFiscalYear = Convert.ToInt32(_fiscalYearList.Max(o => o.Value));
                        }
                    }

                    if (model.CostCenterList != null)
                    {
                        // Populate Cost Center collection
                        foreach (var item in model.CostCenterList!)
                        {
                            _costCenterList.Add(new SelectListItem { Value = item.UDCValue, Text = HtmlEncoder.Default.Encode(item.UDCDescription) });
                        }
                    }

                    if (model.ExpenditureTypeList != null)
                    {
                        // Populate Project Status collection
                        foreach (var item in model.ExpenditureTypeList!)
                        {
                            _expenditureTypeList.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                        }
                    }
                }

                var ReassignmentVM = new ReassignmentVM()
                {
                    Reassignment = _reassignment,
                    CostCenterList = _costCenterList,
                    ExpenditureTypeList = _expenditureTypeList,
                    FiscalYearList = _fiscalYearList,
                    FormCode = CEAFormCodes.REASSIGN.ToString(),
                    FiscalYear = defaultFiscalYear.ToString(),
                };

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
                    }
                }
                #endregion

                return View(ReassignmentVM);
            }
            catch (Exception ex)
            {
                return View(new ExpensesReportVM()
                {
                    ExpensesReport = null,
                    expensesReportList = null,

                });
            }
        }

        private enum SearchRequisitionType
        {
            ASGNTOME,       // Show requisitions assigned to me
            ASGNTOALL,      // Show requisitions assigned to all
            ASGNTOOTHR      // Show requisitions assigned to others
        }

        public ActionResult LoadAssignedRequisitionList(int requisitionNo, string expenditureType, int fromFiscalYear, int toFiscalYear, string costCenter, int empNo)
        {
            try
            {
                // Fetch database records
                var model = _repository.GetAssignedRequisitionList(requisitionNo, expenditureType, fromFiscalYear, toFiscalYear, costCenter, empNo);
                // Convert data to Json
                //return Json(new { data = model});
                if (model.Count > 0)
                    return Json(new { data = model, status = "success" });
                else
                    return Json(new { data = model, status = "failed" });
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        //[HttpPost]
        public async Task<IActionResult> ReassignApprover(string[] selectedRequisition, int newApproverNo, string newApprName, string newApprEmail, string remarks, int routineSeq, bool onHold)
        {
            try
            {
                string[] requisitionArray = selectedRequisition[0].Split(",");

                string requisitionNumbersArray;

                // trailing the characters
                if (selectedRequisition.Length > 0)
                {
                    //requisitionNo = selectedRequisition[0].Replace("[\"", string.Empty).Replace("\"]", string.Empty);
                    requisitionNumbersArray = selectedRequisition[0].Replace("\"", string.Empty).Replace("\"", string.Empty);
                    //requisitionNumbersArray = selectedRequisition[0].Replace("[", string.Empty).Replace("]", string.Empty);
                }

                List<string> selectedRequisitionList = new List<string>();
                foreach (string item in selectedRequisition)
                {
                    requisitionNumbersArray = item.Replace("\"", string.Empty).Replace("\"", string.Empty);
                    selectedRequisitionList.Add(requisitionNumbersArray);
                }

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
                    }
                }
                #endregion

                string userID = Convert.ToString(TempData["UserID"])!;
                string userEmpName = Convert.ToString(TempData["UserEmpName"])!;
                int CreatedBy = Convert.ToInt32(TempData["UserEmpNo"])!;

                //Save to database
                DBTransResult? dbResult = await _repository.ReassignmentRequisition(selectedRequisitionList, userEmpNo, userEmpName, userID, remarks, newApproverNo, 
                    newApprName, newApprEmail, CreatedBy, routineSeq, onHold);

                if (dbResult != null && dbResult.HasError)
                {

                    ////send notification to the new approver. informing the Reassignment Requisition 
                    // Get Approver Info
                    List<EmployeeInfo> employeeInfo = _projectRepository.GetEmployeeList(newApproverNo);

                    ApproversDetails approversDetails = new ApproversDetails();
                    foreach (var employee in employeeInfo)
                    {
                        approversDetails.ApproverEmpNo = employee.EmpNo;
                        approversDetails.ApproverEmail = employee.Email;
                        approversDetails.ApproverName = employee.EmpName;
                    }

                    string subject = "CEA/MRE Requisition# - Reassignment Notification.";
                    string mailbody = _emailCom.ReAssignRequisitionMailBody(approversDetails, selectedRequisitionList);

                    // Format the message contents
                    string htmLBody = string.Format("<HTML><BODY><p>{0}</p></BODY></HTML>", mailbody);
                    _emailCom.SendEmailToApprovers(subject, mailbody, approversDetails);

                    return Json(new { status = "success" });
                }
                else
                {
                    return Json(new { status = "error" });
                }

            }
            catch (Exception ex)
            {
                throw new Exception("Unable to send the email to the new approver.");
            }
        }
    }
}
