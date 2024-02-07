using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using CEAApp.Web.Models;
using CEAApp.Web.ViewModels;
using CEAApp.Web.Repositories;
using CEAApp.Web.Helpers;
using Microsoft.AspNetCore.Mvc.Rendering;
using System.Collections.ObjectModel;
using System.Text;
using System.Text.Encodings.Web;
using iText.Html2pdf;
using static CEAApp.Web.Models.GlobalSettings;
using CEAApp.Web.Areas.UserFunctions.Controllers;
using CEAApp.Web.DIServices;
using Microsoft.Extensions.FileProviders;

namespace CEAApp.Web.Areas.ReportFunctions.Controllers
{
    //[Authorize]
    [Area("ReportFunctions")]
    public class ReportController : Controller
    {
        #region Members
        private readonly IExpensesReportRepository _repository;
        private readonly SecurityController _securityController;
        private readonly IConverterService _converter;
        private readonly IFileProvider _fileProvider;
        private int defaultFiscalYear = DateTime.Now.Year;
        #endregion

        #region Properties
        [BindProperty(SupportsGet = true)]
        public string? CallerForm { get; set; }
        #endregion

        public ReportController(IExpensesReportRepository repository, SecurityController securityController,IConverterService converter, IFileProvider fileProvider)
        {
            _repository = repository;
            _securityController = securityController;
            _converter= converter;
            _fileProvider = fileProvider;
        }

        public async Task<IActionResult> ExpenseReport()
        {
            try
            {
               
                List<SelectListItem> _fiscalYearList = new List<SelectListItem>();
                List<SelectListItem> _costCenterList = new List<SelectListItem>();
                List<SelectListItem> _expenseTypeList = new List<SelectListItem>();

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

                    if (model.ExpenseTypeList != null)
                    {
                        // Populate Project Status collection
                        foreach (var item in model.ExpenseTypeList!)
                        {
                            _expenseTypeList.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                        }
                    }
                }

                ExpensesReport expensesReport = new ExpensesReport();
                expensesReport.FiscalYear = Convert.ToInt16(defaultFiscalYear);
                var expenseReportVM = new ExpensesReportVM()
                {
                    ExpensesReport = expensesReport,
                    costCenterList = _costCenterList,
                    ExpenseTypeList = _expenseTypeList,
                    FiscalYearList = _fiscalYearList,
                    FormCode = CEAFormCodes.EXPENSERPT.ToString(),
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

                return View(expenseReportVM);
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

        public ActionResult LoadExpenseReport(string costCenter, string expenditureType, int? fromFiscalYear, int? toFiscalYear, string projectStatusId, int requisitionStatusId, int startRowIndex, int maximumRows)
        {
            try
            {
                var model = _repository.LoadExpenseReportAsync(costCenter, expenditureType, fromFiscalYear, toFiscalYear, projectStatusId, requisitionStatusId, startRowIndex, maximumRows);

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

                return Json(new { data = model });
            }
            catch (Exception ex)
            {
                throw new Exception(ex.GetBaseException().Message, ex.GetBaseException());
            }
        }

        public ActionResult LoadCostCenter(int currentUser)
        {
            try
            {
                var model = ""; // _repository.GetCostCenterAsync(currentUser);
                return Json(new { data = model });
            }
            catch (Exception ex)
            {
                throw new Exception(ex.GetBaseException().Message, ex.GetBaseException());
            }
        }

        public async Task<IActionResult> DetailedExpenseReport()
        {
            List<SelectListItem> _fiscalYearList = new List<SelectListItem>();
            List<SelectListItem> _costCenterList = new List<SelectListItem>();
            List<SelectListItem> _expenseTypeList = new List<SelectListItem>();

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

                if (model.ExpenseTypeList != null)
                {
                    // Populate Project Status collection
                    foreach (var item in model.ExpenseTypeList!)
                    {
                        _expenseTypeList.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                    }
                }
            }

            DetailedExpensesReport detailedExpensesReport = new DetailedExpensesReport();
            detailedExpensesReport.FiscalYear = Convert.ToInt16(defaultFiscalYear);
            var detailedExpenseVM = new DetailedExpensesReportVM()
            {
                DetailedExpensesReport = detailedExpensesReport,
                costCenterList = _costCenterList,
                ExpenseTypeList = _expenseTypeList,
                FiscalYearList = _fiscalYearList,
                FormCode = CEAFormCodes.DETLEXPRPT.ToString(),
               
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

            return View(detailedExpenseVM);
        }

        public async Task<IActionResult> LoadDetailedExpenseReport(string? costCenter, string? expenditureType, int? fromFiscalYear, int? toFiscalYear, string projectStatusId, int requisitionStatusId, int startRowIndex, int maximumRows)
        {
            try
            {
                await Task.Yield();
                var model = _repository.LoadDetailedExpenseReportAsync(costCenter, expenditureType, fromFiscalYear, toFiscalYear, projectStatusId, requisitionStatusId, startRowIndex, maximumRows);

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
                return Json(new { data = model });
            }
            catch (Exception ex)
            {
                throw new Exception(ex.GetBaseException().Message, ex.GetBaseException());
            }
        }

        public async Task<IActionResult> RequisitionReport()
        {
            List<SelectListItem> _fiscalYearList = new List<SelectListItem>();
            List<SelectListItem> _costCenterList = new List<SelectListItem>();
            List<SelectListItem> _expenseTypeList = new List<SelectListItem>();

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

                if (model.ExpenseTypeList != null)
                {
                    // Populate Project Status collection
                    foreach (var item in model.ExpenseTypeList!)
                    {
                        _expenseTypeList.Add(new SelectListItem { Value = item.UDCValue, Text = item.UDCDescription });
                    }
                }
            }

            RequisitionReport requisitionReport = new RequisitionReport();
            requisitionReport.FiscalYear = Convert.ToInt16(defaultFiscalYear);
            var detailedExpenseVM = new RequisitionReportVM()
            {
                RequisitionReport = requisitionReport,
                costCenterList = _costCenterList,
                ExpenseTypeList = _expenseTypeList,
                FiscalYearList = _fiscalYearList,
                FormCode = CEAFormCodes.REQUESTRPT.ToString(),
            };

            return View(detailedExpenseVM);
        }


        public async Task<IActionResult> LoadRequisitionReport(string costCenter, string expenditureType, int? fromFiscalYear, int? toFiscalYear, string projectStatusId, int requisitionStatusId, int startRowIndex, int maximumRows)
        {
            try
            {
                //await Task.Yield();
                var model = await  _repository.LoadRequisitionReportAsync(costCenter, expenditureType, fromFiscalYear, toFiscalYear, projectStatusId, requisitionStatusId, startRowIndex, maximumRows);
                return Json(new { data = model });
            }
            catch (Exception ex)
            {
                throw new Exception(ex.GetBaseException().Message, ex.GetBaseException());
            }
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

        public async Task<IActionResult> RequisitionPrint(int requisitionId, string projectNo = "")
        {
            try
            {
                var model = await _repository.LoadRequisitionPrintAsync(requisitionId);

                var modelApprover = await _repository.LoadRequisitionApproverPrintAsync(requisitionId);

                var modelExpenses = await _repository.LoadRequisitionExpensesPrintAsync(requisitionId);

                StringBuilder sb = new StringBuilder(string.Empty);

                string HTMLContent = sb.ToString();// Put your html tempelate here

                sb.Append("<table cellpadding='5' cellspacing='0' style='border: 1px solid #000000;font-size: 9pt;font-family:Arial; width:100%; height:50px;'>");
                sb.Append("<tr  style='width:100%;'>");
                sb.Append("<td style='width:10%;'>" + "<img src='../CEAApp.Web/wwwroot/images/garmco_logo.png'>" + "</td>");
                sb.Append("<td style='width:80%;font-size:20px;text-align: center; '>" + model[0].ExpenditureType + "</td>");
                sb.Append("</tr>");
                sb.Append("</table>");
                sb.Append("<div style='width:100%;height:5px;'></div>");

                //Item Required:
                sb.Append("<table  cellpadding='5' cellspacing='0' style='border: .5px solid #000000; font-size: 9pt;font-family:Arial; width:100%;'>");
                sb.Append("<tr style='width:100%;'>");
                sb.Append("<td style='width:20%;border: .5px solid #000000;font-weight: bold;'>" + "Item Required:" + "</td>");
                sb.Append("<td style='width:30%;border: .5px solid #000000'>" + model[0].Description + "</td>");

                sb.Append("<td cellpadding='5' cellspacing='0' style='width:50%;border: .5px solid #000000'>");
                //Requisition No:
                sb.Append("<table cellpadding='5' cellspacing='0' style='width:100%;;border: 0px;'>");
                sb.Append("<tr style='width:100%;'> <td style='width:40%;border: .5px solid #000000;font-weight: bold;'>" + "Requisition No:" + "</td> <td style='width:60%;border: .5px solid #000000'>" + model[0].RequisitionNo + "</td> </tr>");
                sb.Append("<tr style='width:100%;'> <td style='width:40%;border: .5px solid #000000;font-weight: bold;'>" + "Status:" + "</td> <td style='width:60%;border: .5px solid #000000'>" + model[0].RequisitionStatus + "</td></tr>");
                sb.Append("<tr style='width:100%;'> <td style='width:40%;border: .5px solid #000000;font-weight: bold;'>" + "Date Requested:" + "</td> <td style='width:60%;border: .5px solid #000000'>" + model[0].CreateDate + "</td></tr>");
                sb.Append("<tr style='width:100%;'> <td style='width:40%;border: .5px solid #000000;font-weight: bold;'>" + "Total Project Cost:" + "</td> <td style='width:60%;border: .5px solid #000000'>" + model[0].RequestedAmt + " BD" + "</td> </tr>");
                sb.Append("</table>");

                sb.Append("</td>");
                sb.Append("</tr>");
                sb.Append("</table>");
                sb.Append("<div style='width:100%;height:5px;'></div>");

                //Reason For Requisitionsss
                sb.Append("<table cellpadding='5' cellspacing='0' style='border: .5px solid #000000; font-size: 9pt;font-family:Arial; width:100%;'>");
                sb.Append("<tr style='width:100%;'>");
                sb.Append("<td style='width:20%;border: .5px solid #000000;font-weight: bold;'>" + "Reason For Requisition:" + "</td>");
                sb.Append("<td style='width:80%;border: .5px solid #000000'>" + model[0].Reason + "</td>");
                sb.Append("</tr>");
                sb.Append("</table>");
                sb.Append("<div style='width:100%;height:5px;'></div>");

                //Project No
                sb.Append("<table cellpadding='5' cellspacing='0' style='border: .5px solid #000000; font-size: 9pt;font-family:Arial; width:100%;'>");
                sb.Append("<tr style='width:100%;'> <td style='border: .5px solid #000000;width:20%;text-align:left;font-weight: bold;'>" + "Project No:" + "</td>");
                sb.Append("<td style='border: .5px solid #000000;width:30%;text-align:left;'>" + model[0].ProjectNo + "</td>");
                sb.Append("<td style='border: .5px solid #000000;width:20%;text-align:left;font-weight: bold;'>" + "Cost Center:" + "</td>");
                sb.Append("<td style='border: .5px solid #000000;width:30%;text-align:left;'>" + model[0].CostCenerID + "</td></tr>");

                sb.Append("<tr style='width:100%;'> <td style='border: .5px solid #000000;width:20%;text-align:left;font-weight: bold;'>" + "Plant Location:" + "</td>");
                sb.Append("<td style='border: .5px solid #000000;width:30%;text-align:left;'>" + model[0].PlantLocationID + "</td>");
                sb.Append("<td style='border: .5px solid #000000;width:20%;text-align:left;font-weight: bold;'>" + "Est. Life Span:" + "</td>");
                sb.Append("<td style='border: .5px solid #000000;width:30%;text-align:left;'>" + model[0].EstimatedLifeSpan + " Years/s" + "</td></tr>");

                sb.Append("<tr style='width:100%;'> <td style='border: .5px solid #000000;width:20%;text align:left;font-weight: bold;'>" + "Equipment Parent No:" + "</td>");
                sb.Append("<td style='border: .5px solid #000000;width:30%;text-align:left;'>" + model[0].EquipmentParentNo + "</td>");
                sb.Append("<td style='border: .5px solid #000000;width:20%;text-align:left;font-weight: bold;'>" + "Commissioning Date:" + "</td>");
                sb.Append("<td style='border: .5px solid #000000;width:30%;text-align:left;'>" + model[0].DateofComission + "</td></tr>");

                sb.Append("<tr style='width:100%;'> <td style='border: .5px solid #000000;width:20%;text-align:left;font-weight: bold;'>" + "Equipment Child No:" + "</td>");
                sb.Append("<td style='border: .5px solid #000000;width:30%;text-align:left;'>" + model[0].EquipmentNo + "</td>");
                sb.Append("<td style='border: .5px solid #000000;width:20%;text-align:left;font-weight: bold;'>" + "Description:" + "</td>");
                sb.Append("<td style='border: .5px solid #000000;width:30%;text-align:left;'>" + model[0].RequisitionDescription + " </td></tr>");

                sb.Append("</table>");
                sb.Append("<div style='width:100%;height:5px;'></div>");

                //Originator
                sb.Append("<table cellpadding='5' cellspacing='0' style='border: .5px solid 000000; font-size: 9pt;font-family:Arial; width:100%;'>");
                sb.Append("<tr style='width:100%;'>");
                sb.Append("<td style='width:20%;border: .5px solid #000000; text-align:left;font-weight: bold;'>" + "Originator:" + "</td>");
                sb.Append("<td style='width:30%;border: .5px solid #000000; text-align:left;'>" + model[0].Originator + "</td>");
                sb.Append("<td style='width:20%;border: .5px solid #000000; text-align:left;font-weight: bold;'>" + "Department:" + "</td>");
                sb.Append("<td style='width:30%;border: .5px solid #000000; text-align:left;'>" + model[0].CostCener + " </td></tr>");
                sb.Append("</table>");
                sb.Append("<div style='width:100%;height:5px;'></div>");

                //Approved By
                sb.Append("<table cellpadding='5' cellspacing='0' style='border: .5px solid #000000; font-size: 9pt; font-family:Arial; width:100%;'>");
                sb.Append("<tr style='width:100%;'> <th style='border: .5px solid #000000; width:33.33%;text-align:center;'>Approved By</th> <th style='border: .5px solid #000000;width:33.33%;text-align:center;'>Role</th>  <th style='border: .5px solid #000000;width:33.33%;text-align:center;'>Date and Time</th></tr>");
                sb.Append("<tr style='width:100%;'> <td style='border: .5px solid #000000; width:33.33%;text-align:center;'>" + (modelApprover.Count > 0 ? _converter.ConvertObjectToString(modelApprover[0].Name!) : string.Empty) + "</td>");
                sb.Append("<td style='border: .5px solid #000000; width:33.33%;text-align:center;'>" + (modelApprover.Count > 0 ? _converter.ConvertObjectToString(modelApprover[0].Role!) : string.Empty) + " </td>");
                sb.Append("<td style='border: .5px solid #000000; width:33.33%;text-align:center;'>" + (modelApprover.Count > 0 ? _converter.ConvertObjectToString(modelApprover[0].DateTimeApproved!) : string.Empty) + " </td></tr>");
                sb.Append("</table>");
                sb.Append("<div style='width:100%;height:5px;'></div>");

                //Approved Budget:
                sb.Append("<table  cellpadding='5' cellspacing='0' style='border: .5px solid #000000; font-size: 9pt;font-family:Arial; width:100%;'>");
                sb.Append("<tr style='width:100%; border: .5px solid #000000;'> <td style='border: .5px solid #000000;width:20%;text-align:left;font-weight: bold;'>" + "Approved Budget:" + "</td>");
                sb.Append("<td style='border: .5px solid #000000;width:60%;text-align:left;'></td>");
                sb.Append("<td style='border: .5px solid #000000;width:20%;text-align:left;'>" + model[0].ProjectAmount + "</td></tr>");
                sb.Append("<tr style='border: .5px solid #000000;'> <td  style='border: .5px solid #000000;width:20%;text-align:left;font-weight: bold;'>" + "Additional Amount Requested:" + " </td>");
                sb.Append("<td style='border: .5px solid #000000;width:60%;text-align:left;'>" + model[0].ReasonForAdditionalAmt + "</td>");
                sb.Append("<td style='border: .5px solid #000000;width:20%;text-align:left;'>" + model[0].UsedAmt + "</td></tr>");
                sb.Append("<tr style='border: .5px solid #000000;border: .5px solid #000000;'> <td  style='border: .5px solid #000000;width:20%;text-align:left;'>" + "" + " </td>");
                sb.Append("<td style='border: .5px solid #000000;width:60%;text-align:left;font-weight: bold;font-weight: bold;'>" + "Total project amount requested" + "</td>");
                sb.Append("<td style='border: .5px solid #000000;width:20%;text-align:left;font-weight: bold;'>" + model[0].ProjectBalanceAmt + "</td></tr>");
                sb.Append("</table>");
                sb.Append("<div style='width:100%;height:5px;'></div>");

                //Account No:
                sb.Append("<table  cellpadding='5' cellspacing='0' style='border: 1px solid #000000; font-size: 9pt;font-family:Arial; width:100%;'>");
                sb.Append("<tr style='width:100%;'> <td style='border: .5px solid #000000;width:20%;text-align:left;font-weight: bold;'>" + "Account No:" + "</td>");
                sb.Append("<td style=''border: .5px solid #000000;width:90%;text-align:left;'>" + model[0].AccountNo + " - " + model[0].AccountDescription + "</td></tr>");
                sb.Append("</table>");
                sb.Append("<div style='width:100%;height:5px;'></div>");

                //Schedule of Expenses
                sb.Append("<div style='border: .5px solid #000000; font-size: 9pt;font-family:Arial; width:99.8%;font-weight: bold;'>Schedule of Expenses:</div>");
                sb.Append("<table cellpadding='2' cellspacing='0' style='width:100%;height:100px; border: .5px solid #000000; text-align:left; padding:0px!important;font-size:9pt;font-family:Arial;'>");
                sb.Append("<tr style='width:100%;border: .5px solid #000000;'> <th style='width:33%;border: .5px solid #000000;text-align:left;font-weight: bold;'>Year</th> <th style='width:33%;border: .5px solid #000000;text-align:left;font-weight:bold;'>Quarter</th>  <th style='width:33%;border: .5px solid #000000;text-align:right;font-weight:bold;'>Amount</th></tr>");
                //loop here
                for (int i = 0; i < modelExpenses.Count; i++)
                {
                    sb.Append("<tr style='border: .5px solid #000000;'><td style='width:33%;border: .5px solid #000000;text-align:left;'>" + modelExpenses[i].FiscalYear + "</td>");
                    sb.Append("<td style='width:33%;border: .5px solid #000000;text-align:left;'>" + modelExpenses[i].Quarter + " </td>");
                    sb.Append("<td style='width:33%;border: .5px solid #000000;text-align:right;'>" + modelExpenses[i].Amount + " BD" + " </td></tr>"); // loop end
                }
                sb.Append("</table>");
                sb.Append("<div style='width:100%;height:5px;'></div>");

                sb.Append("<table cellpadding='5' cellspacing='0' style='width:100%;border: .5px solid #000000; text-align:left; padding:0px!important;font-size:9pt;font-family:Arial;'>");
                sb.Append("<tr><td style='width:49%;border: .5px solid #000000; text-align:left;font-size:9pt;font-family:Arial;'> ");
                sb.AppendLine("<div style='padding:0px!important;font-weight: bold;'>Approved By </div>");
                sb.AppendLine("<div style='height:25px;'></div>");
                sb.AppendLine("<div>__________________ </div>");
                sb.AppendLine("</td>");
                sb.Append("<td style='width:49%;border: .5px solid #000000; text-align:left;font-size:9pt;font-family:Arial;'> ");
                sb.AppendLine("<div style='padding:0px!important;font-weight: bold;'>Approved By </div>");
                sb.AppendLine("<div style='height:25px;'></div>");
                sb.AppendLine("<div>__________________ </div>");
                sb.AppendLine("</td></tr>");
                sb.Append("<tr><td style='width:49%;border: .5px solid #000000; text-align:left;font-size:9pt;font-family:Arial;'> ");

                sb.AppendLine("<div style='padding:0px!important;font-weight: bold;'>Cheif Executive Officer </div>");
                sb.AppendLine("<div style='height:10px;font-weight: bold;'></div>");
                sb.AppendLine("<div>Date:</div>");
                sb.AppendLine("</td>");
                sb.Append("<td style='width:49%;border: .5px solid #000000; text-align:left; font-size:9pt;font-family:Arial;'> ");
                sb.AppendLine("<div style='padding:0px!important;font-weight: bold;'>Chairman</div>");
                sb.AppendLine("<div style='height:10px;font-weight: bold;'></div>");
                sb.AppendLine("<div>Date:</div>");
                sb.AppendLine("</td></tr>");
                sb.Append("</table>");
                sb.Append("<div style='width:100%;height:5px;'></div>");

                sb.Append("<table cellpadding='5' cellspacing='0' style='width:100%;font-size:8pt;font-family:Arial;'> <tr> <td style='width:5%;border: 0px solid #000000; text-align:left; padding:0px!important;'> Distribution: </td>");
                sb.Append("<td style='width:75%;font-family:Arial;text-align:left;'> Original retained by Finance </td>");
                sb.Append("<td style='width:20%;font-family:Arial;text-align:left;'> " + DateTime.Now + "</td></tr>");
                sb.Append("<tr><td style='width:5%;font-family:Arial;'>  </td>");
                sb.Append("<td style='width:75%;text-align:left; padding:0px!important;font-family:Arial;'> 2 Copies to originator who will retain one and forward the other to Purchasing with requisition </td>");
                sb.Append("<td style='width:20%;'></td></tr></table>");

                //ViewBag.Report = sb.ToString();

                //TempData["CEAReportData"] = sb.ToString();
                //RedirectToAction("CEARequisition", "Project", new
                //{
                //    area = "UserFunctions",
                //    projectNo = projectNo,
                //    requisitionNo = requisitionId,
                //    actionType = Convert.ToInt32(GlobalSettings.ActionTypeOption.ShowReport).ToString()
                //});


                using (MemoryStream stream = new MemoryStream())
                {
                    HtmlConverter.ConvertToPdf(sb.ToString(), stream);
                    //return File(stream.ToArray(), "application/pdf", "Requisition.pdf");
                    //return File(stream.ToArray(), "application/octet-stream", "Requisition.pdf");

                    // opening the pdf file in New Tab 
                    string? filepath = ((PhysicalFileProvider)_fileProvider).Root + "FileAttachments\\" + "Requisition.pdf";
                    if (System.IO.File.Exists(filepath))
                    {
                        System.IO.File.Delete(filepath);
                    }
                    System.IO.File.WriteAllBytes(filepath, stream.ToArray());
                    stream.Close();
                    return new PhysicalFileResult(filepath, "application/pdf");
                }

            }
            catch (Exception err)
            {
                // Open the error page
                return RedirectToAction("Error", "Security", new 
                { 
                    area = "UserFunctions",
                    actionName = "Printing CEA report",
                    offendingURL = "~/Report/RequisitionPrint",
                    source = err.Source,    
                    message = err.Message,
                    innerMessage = err.InnerException,  
                    stackTrace = err.StackTrace,
                    callerForm = this.CallerForm
                });
            }
        }
    }

}
