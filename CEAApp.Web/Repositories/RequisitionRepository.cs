using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.Data.SqlClient;
using System.Data;
using CEAApp.Web.Models;
using CEAApp.Web.Helpers;
using Microsoft.EntityFrameworkCore;
using CEAApp.Web.DIServices;
using System.Data.Common;
using Dapper;
using CEAApp.Web.ViewModels;
using iText.Html2pdf.Html;
using Microsoft.AspNetCore.Http;
using static Microsoft.Extensions.Logging.EventSource.LoggingEventSource;
using static Microsoft.EntityFrameworkCore.DbLoggerCategory.Database;
using Microsoft.DotNet.Scaffolding.Shared.Project;
using iText.StyledXmlParser.Jsoup.Nodes;
using System.Linq;
using iText.Forms.Xfdf;
using System.Drawing;
using static Org.BouncyCastle.Math.EC.ECCurve;
using System.ServiceModel;
using WFServiceProxy;
using System.ServiceModel.Description;

namespace CEAApp.Web.Repositories
{
    public class RequisitionRepository : IRequisitionRepository
    {
        #region Fields
        private readonly ApplicationDbContext _db;
        private readonly string? _connectionString;
        private readonly IConverterService _converter;
        private IDbConnection _dapperDB = null;
        #endregion

        #region Properties
        public ReferenceData LookupData { get; set; } = new ReferenceData();
        private readonly IConfiguration _config;
        private readonly string? _gapConnectionString;
        private readonly string? _wfConnectionString;

        private CommonWFServiceClient WorkflowServiceProxy
        {
            get
            {
                try
                {
                    var appSettingOptions = new AppSettingOptions();
                    _config.GetSection(AppSettingOptions.AppSettings).Bind(appSettingOptions);

                    string DynamicEndpointAddress = appSettingOptions.WFEngineURL;
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

        public enum ApprovalStatusCode
        {
            Approved,
            UploadtoOneWorld,
            AwaitingChairmanApproval,
            ChairmanApproved

        }

        #region Constructors
        public RequisitionRepository(ApplicationDbContext context, IConfiguration configuration, IConverterService converter)
        {
            _db = context;
            _connectionString = configuration.GetConnectionString("CEAConnectionString");
            _converter = converter;
            _gapConnectionString = configuration.GetConnectionString("GAPConnectionString");
            _wfConnectionString = configuration.GetConnectionString("WFConnectionString");
            _config = configuration;
        }
        #endregion

        #region Public Methods
        public async Task<ReferenceData> GetLookupTable()
        {
            ReferenceData model = null;
            try
            {
                //List<FiscalYearEntity> fiscalYearList = new List<FiscalYearEntity>();
                List<UserdefinedCode> fiscalYearList = new List<UserdefinedCode>();
                List<UserdefinedCode> costCenterList = new List<UserdefinedCode>();
                List<UserdefinedCode> projectStatusList = new List<UserdefinedCode>();
                List<UserdefinedCode> expenditureTypeList = new List<UserdefinedCode>();
                List<UserdefinedCode> requisitionStatusList = new List<UserdefinedCode>();
                List<UserdefinedCode> expenseTypeList = new List<UserdefinedCode>();

                DbCommand cmd;
                DbDataReader reader;

                string sql = "EXEC Projectuser.Pr_GetLookupTable";

                // Build the command object
                cmd = _db.Database.GetDbConnection().CreateCommand();
                cmd.CommandText = sql;

                // Create parameters
                //cmd.Parameters.Add(new SqlParameter { ParameterName = "@objectCode", SqlDbType = SqlDbType.VarChar, Size = 20, Value = objectCode });

                // Open database connection
                await _db.Database.OpenConnectionAsync();

                // Create a DataReader  
                reader = await cmd.ExecuteReaderAsync(CommandBehavior.CloseConnection);

                #region Get the Fiscal Year list
                while (await reader.ReadAsync())
                {
                    fiscalYearList.Add(new UserdefinedCode
                    {
                        UDCValue = _converter.ConvertObjectToString(reader["FiscalYearValue"]),
                        UDCDescription = _converter.ConvertObjectToString(reader["FiscalYearDesc"])
                    });
                }
                #endregion

                // Advance to the next result set  
                reader.NextResult();

                #region Get the cost center list
                while (await reader.ReadAsync())
                {
                    costCenterList.Add(new UserdefinedCode
                    {
                        UDCValue = _converter.ConvertObjectToString(reader["CostCenter"]),
                        UDCDescription = _converter.ConvertObjectToString(reader["CostCenterName"])
                    });
                }
                #endregion

                // Advance to the next result set  
                reader.NextResult();

                #region Get the Project Status list
                while (await reader.ReadAsync())
                {
                    projectStatusList.Add(new UserdefinedCode
                    {
                        UDCValue = _converter.ConvertObjectToString(reader["StatusCode"]),
                        UDCDescription = _converter.ConvertObjectToString(reader["ApprovalStatus"])
                    });
                }
                #endregion

                // Advance to the next result set  
                reader.NextResult();

                #region Get the Expenditure Type list
                while (await reader.ReadAsync())
                {
                    expenditureTypeList.Add(new UserdefinedCode
                    {
                        UDCValue = _converter.ConvertObjectToString(reader["DetailRefCode"]),
                        UDCDescription = _converter.ConvertObjectToString(reader["DetailRefCodeDescription"])
                    });
                }
                #endregion

                #region Get the Expense Types
                // Advance to the next result set  
                reader.NextResult();

                while (await reader.ReadAsync())
                {
                    expenseTypeList.Add(new UserdefinedCode
                    {
                        UDCValue = _converter.ConvertObjectToString(reader["ExpenditureTypeCode"]),
                        UDCDescription = _converter.ConvertObjectToString(reader["ExpenditureTypeDesc"])
                    });
                }
                #endregion

                // Advance to the next result set  
                reader.NextResult();

                #region Get the requisitionStatus list
                while (await reader.ReadAsync())
                {
                    requisitionStatusList.Add(new UserdefinedCode
                    {
                        UDCValue = _converter.ConvertObjectToString(reader["StatusCode"]),
                        UDCDescription = _converter.ConvertObjectToString(reader["StatusDescription"])
                    });
                }
                #endregion

                // Close reader and database connection
                await reader.CloseAsync();

                // Initialize the model properties
                model = new ReferenceData()
                {
                    FiscalYearList = fiscalYearList,
                    CostCenterList = costCenterList,
                    ProjectStatusList = projectStatusList,
                    ExpenditureTypeList = expenditureTypeList,
                    RequisitionStatusList = requisitionStatusList
                };

                return model;
            }
            catch (SqlException sqlErr)
            {
                throw new Exception(sqlErr.Message.ToString());
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        public async Task<List<Requisition>> LoadRequisitionAsync(string costCenter, string expenditureType, int? fiscalYear, string projectNo, string requisitionStatus, int requisitionNo, string keywords,
             bool filterToUser, int employeeNo)
        {
            try
            {

                List<Requisition> list = null;
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@projectNo", projectNo ?? null, DbType.String, ParameterDirection.Input, 10);
                    parameters.Add("@requisitionNo", requisitionNo == 0 ? null : requisitionNo, DbType.String, ParameterDirection.Input, 50);
                    parameters.Add("@expenditureType", expenditureType ?? null, DbType.String, ParameterDirection.Input, 12);
                    parameters.Add("@fiscalYear", fiscalYear, DbType.Int32, ParameterDirection.Input);
                    parameters.Add("@statusCode", requisitionStatus ?? null, DbType.String, ParameterDirection.Input);
                    parameters.Add("@costCenter", costCenter ?? null, DbType.String, ParameterDirection.Input);
                    parameters.Add("@empNo", employeeNo , DbType.Int32, ParameterDirection.Input);
                    parameters.Add("@approvalType", null, DbType.String, ParameterDirection.Input);
                    parameters.Add("@keywords", keywords ?? null, DbType.String, ParameterDirection.Input, 50);
                    parameters.Add("@startDate", null, DbType.Date, ParameterDirection.Input);
                    parameters.Add("@endDate", null, DbType.Date, ParameterDirection.Input);

                    var model = _dapperDB.Query("Projectuser.Pr_SearchRequisition", parameters, commandType: CommandType.StoredProcedure).ToList();

                    if (model.Count > 0)
                    {
                        list = new List<Requisition>();

                        foreach (var item in model)
                        {
                            list.Add(new Requisition()
                            {
                                RequisitionId = item.RequisitionID,
                                ProjectNo = item.ProjectNo,
                                RequisitionNo = item.RequisitionNo,
                                Status = item.Status,
                                RequestDate = _converter.ConvertObjectToDate(item.RequisitionDate),
                                RequisitionDescription = item.Description,
                                DateofComission = _converter.ConvertObjectToDate(item.DateofCommission),
                                RequestedAmt = item.Amount ?? 0,
                                ProjectBalanceAmt = _converter.ConvertObjectToDecimal(item.UsedAmount ?? 0),
                                CostCenter = item.CostCenter,
                                ObjectCode = item.ObjectCode,
                                SubjectCode = item.SubjectCode,
                                AccountCode = item.AccountCode,
                                CompanyCode = _converter.ConvertObjectToString(item.CompanyCode),
                                StatusCode = item.ApprovalStatus,
                                statusHandlingCode = item.StatusHandlingCode,
                                EquipmentNo = item.EquipmentNo,
                                ExpenditureType = item.ExpenditureType,
                                CEAStatusCode = item.CEAStatusCode,
                                CEAStatusDesc = item.CEAStatusDesc,

                                //StatusCodeMsg = (item.StatusCode == (Enum.Parse(typeof(RequisitionStatus), "Approved")).ToString() ? "Upload to OneWorld" :
                                //             item.StatusCode == (Enum.Parse(typeof(RequisitionStatus), "AwaitingChairmanApproval")).ToString() ? "Chairman Approved" : item.StatusCode),
                            });
                        }
                    }
                }

                return list;

            }
            catch (SqlException sqlErr)
            {
                throw new Exception(sqlErr.Message.ToString());
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message.ToString());
            }
        }

        public async Task<List<Requisition>> LoadRequisitionAssignmentAsync(string CostCenter, string ExpenditureType, string ProjectNo, int RequisitionNo, int FromFiscalYear, int ToFiscalYear)
        {
            try
            {
                List<Requisition> list = null;
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@CostCenter", CostCenter, DbType.String, ParameterDirection.Input);
                    parameters.Add("@ExpenditureType", ExpenditureType, DbType.String, ParameterDirection.Input);
                    parameters.Add("@ProjectNo", ProjectNo, DbType.String, ParameterDirection.Input);
                    parameters.Add("@RequisitionNo", RequisitionNo, DbType.String, ParameterDirection.Input);
                    parameters.Add("@FromFiscalYear", FromFiscalYear, DbType.Int32, ParameterDirection.Input);
                    parameters.Add("@ToFiscalYear", ToFiscalYear, DbType.Int32, ParameterDirection.Input);

                    //await Task.Yield();
                    var model = _dapperDB.Query("Projectuser.Pr_GetRequisitionsToAssignEquipmentNos", parameters, commandType: CommandType.StoredProcedure).ToList();
                    if (model.Count > 0)
                    {
                        list = new List<Requisition>();

                        foreach (var item in model)
                        {
                            list.Add(new Requisition()
                            {
                                ProjectNo = item.ProjectNo,
                                RequisitionNo = item.RequisitionNo,
                                ExpenditureType = item.ExpenditureType,
                                EquipmentNo = item.EquipmentNo,
                                RequisitionDescription = item.RequisitionDescription,
                                RequestedAmt = item.RequestedAmt ?? 0,

                                AccountNo = item.AccountNo,
                                EstimatedLifeSpan = item.EstimatedLifeSpan,
                                Description = item.RequisitionDescription,
                                Reason = item.Reason,

                            });
                        }
                    }
                }

                return list;

            }
            catch (SqlException sqlErr)
            {
                throw new Exception(sqlErr.Message.ToString());
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message.ToString());
            }
        }

        public async Task<List<Requisition>> LoadEquipmentNoAsync(string RequisitionNo)
        {
            try
            {
                string SearchCriteria = string.Empty;
                string SearchValue = string.Empty;

                List<Requisition> list = null;
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@SearchCriteria", SearchCriteria, DbType.String, ParameterDirection.Input);
                    parameters.Add("@SearchValue", SearchValue, DbType.String, ParameterDirection.Input);
                    //await Task.Yield();
                    var model = _dapperDB.Query("Projectuser.spGetEquipmentNumbers-New", parameters, commandType: CommandType.StoredProcedure).ToList();
                    if (model.Count > 0)
                    {
                        list = new List<Requisition>();

                        foreach (var item in model)
                        {
                            list.Add(new Requisition()
                            {
                                EquipmentNo = item.EquipmentNo.Trim(),
                                EquipmentParentNo = item.ParentEquipmentNo.Trim(),
                                EquipmentDescription = item.EquipmentDescription,
                                EquipmentParentDescription = item.ParentEquipmentDescription
                            });
                        }
                    }
                }

                return list;

            }
            catch (SqlException sqlErr)
            {
                throw new Exception(sqlErr.Message.ToString());
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message.ToString());
            }
        }

        public async Task<DBTransResult?> SaveEquipmentNoAsync(string RequisitionNo, string EquipmentNo, string ParentEquipmentNo, string IsEquipmentNoRequired)
        {
            try
            {
                DBTransResult? dbResult = null;
                int rowsAffected = 0;
                string SearchCriteria = string.Empty;
                string SearchValue = string.Empty;

                List<Requisition> list = null;
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@RequisitionNo", RequisitionNo, DbType.String, ParameterDirection.Input);
                    parameters.Add("@EquipmentNo", EquipmentNo, DbType.String, ParameterDirection.Input);
                    parameters.Add("@EquipmentParentNo", ParentEquipmentNo, DbType.String, ParameterDirection.Input);
                    parameters.Add("@EquipmentNoMandatory", IsEquipmentNoRequired, DbType.String, ParameterDirection.Input);
                    //await Task.Yield();
                    //var model = _dapperDB.Query("Projectuser.spUpdateEquipmentNumber", parameters, commandType: CommandType.StoredProcedure).ToList();

                    // Save to database
                    rowsAffected = _dapperDB.Execute("Projectuser.spUpdateEquipmentNumber", parameters, commandType: CommandType.StoredProcedure);
                    if (rowsAffected == 1)
                    {
                        dbResult = new DBTransResult()
                        {
                            RowsAffected = rowsAffected,
                            HasError = false
                        };
                    }

                }

                return dbResult;

            }
            catch (SqlException sqlErr)
            {
                throw new Exception(sqlErr.Message.ToString());
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message.ToString());
            }
        }

        public async Task<int> UploadToOneWorld(int requisitionID, int CompanyCode, string costCenter, string objectCode, string subjectCode,
                                                                      string accountCode, string requisitionAmount, string userID, string workstationID)
        {
            using (_dapperDB = new SqlConnection(_connectionString))
            {
                var parameters = new DynamicParameters();
                parameters.Add("@RequisitionID", requisitionID, DbType.String, ParameterDirection.Input);
                parameters.Add("@CompanyID", CompanyCode, DbType.String, ParameterDirection.Input);
                parameters.Add("@CostCenter", costCenter, DbType.String, ParameterDirection.Input);
                parameters.Add("@UserID", userID, DbType.String, ParameterDirection.Input);
                parameters.Add("@WorkStationID", workstationID, DbType.String, ParameterDirection.Input);
                parameters.Add("@ObjectAccount", objectCode, DbType.String, ParameterDirection.Input);
                parameters.Add("@SubjectAccount", subjectCode, DbType.String, ParameterDirection.Input);
                parameters.Add("@AccountCode", accountCode, DbType.String, ParameterDirection.Input);
                parameters.Add("@requisitionAmount", requisitionAmount, DbType.String, ParameterDirection.Input);

                //await Task.Yield();
                var model = _dapperDB.Query("Projectuser.Pr_UploadCEADataToOneWorld", parameters, commandType: CommandType.StoredProcedure).ToList();

            }

            return 1;
        }

        public async Task<bool> UpdateRequisitionStatus(string statusCode, int requisitionID, string employeeNo, string approverComment)
        {

            using (_dapperDB = new SqlConnection(_connectionString))
            {
                var parameters = new DynamicParameters();
                parameters.Add("@StatusCode", statusCode, DbType.String, ParameterDirection.Input);
                parameters.Add("@RequisitionID", requisitionID, DbType.String, ParameterDirection.Input);
                parameters.Add("@EmpNo", employeeNo, DbType.String, ParameterDirection.Input);
                parameters.Add("@ApproverComment", approverComment, DbType.String, ParameterDirection.Input);

                //await Task.Yield();
                var model = _dapperDB.Query("Projectuser.spUpdateRequisitionStatus", parameters, commandType: CommandType.StoredProcedure).ToList();

            }

            return true;
        }

        public async Task<bool> CloseRequisitionUpdationToOneWorld(int requisitionID)
        {

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@RequisitionID", requisitionID, DbType.String, ParameterDirection.Input);
                    //await Task.Yield();
                    var model = _dapperDB.Query("Projectuser.spCloseRequisitionUpdationToOneWorld", parameters, commandType: CommandType.StoredProcedure).ToList();

                }
                return true;
            }
            catch (Exception ex)
            {
                throw new Exception("Error Occured while updating Requisition close status to OneWorld. " + ex.Message);
            }

        }

        public async Task<List<ApproversDetails>> LoadApproversDetailsAsync(int requisitionID)
        {
            try
            {
                List<ApproversDetails> list = null;
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@RequisitionID", requisitionID, DbType.Int32, ParameterDirection.Input);

                    //await Task.Yield();
                    var model = _dapperDB.Query("Projectuser.Pr_GetApproversMailList", parameters, commandType: CommandType.StoredProcedure).ToList();
                    if (model.Count > 0)
                    {
                        list = new List<ApproversDetails>();

                        foreach (var item in model)
                        {
                            list.Add(new ApproversDetails()
                            {
                                ApproverEmpNo = item.EmployeeNo,

                                ApproverEmail = item.ApproverEmail,

                                ApproverName = item.User,

                                RequisitionNo = item.RequisitionNo,

                                ApprovalStatus = item.ApprovalStatus,
                            });
                        }
                    }
                }

                return list;

            }
            catch (SqlException sqlErr)
            {
                throw new Exception(sqlErr.Message.ToString());
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message.ToString());
            }
        }
        #endregion

        public List<RequisitionDetail> GetAssignedRequisitionList(int requisitionNo, string expenditureType, int fromFiscalYear = 0, int toFiscalYear = 0, string costCenter="", int empNo = 0)
        {
            List<RequisitionDetail> requisitionList = new List<RequisitionDetail>();

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    DateTime? sDate = _converter.ConvertObjectToDate(fromFiscalYear);
                    DateTime? eDate = _converter.ConvertObjectToDate(toFiscalYear);

                    var parameters = new DynamicParameters();

                    parameters.Add("@projectNo",  null, DbType.String, ParameterDirection.Input, 10);
                    parameters.Add("@requisitionNo", requisitionNo == 0 ? null : requisitionNo, DbType.String, ParameterDirection.Input, 50);
                    parameters.Add("@expenditureType", expenditureType == "All" ? null : expenditureType, DbType.String, ParameterDirection.Input, 12);
                    parameters.Add("@fiscalYear", toFiscalYear, DbType.Int32, ParameterDirection.Input);
                    parameters.Add("@statusCode", null, DbType.String, ParameterDirection.Input);
                    parameters.Add("@costCenter", costCenter == "0" ? null : costCenter, DbType.String, ParameterDirection.Input);
                    parameters.Add("@empNo", null, DbType.Int32, ParameterDirection.Input);
                    parameters.Add("@approvalType", null, DbType.String, ParameterDirection.Input);
                    parameters.Add("@keywords", null, DbType.String, ParameterDirection.Input, 50);
                    parameters.Add("@startDate", null, DbType.Date, ParameterDirection.Input);
                    parameters.Add("@endDate", null, DbType.Date, ParameterDirection.Input);

                    var model = _dapperDB.Query("[Projectuser].[Pr_SearchRequisition]", parameters, commandType: CommandType.StoredProcedure).ToList();

                    // Removing the below approvalstatus
                    //var exceptionList = new List<string> { "Draft", "Closed", "Closed by Approver", "Cancelled", "Cancelled By User", "Rejected",
                    //    "Rejected By Approver", "Request Sent", "Uploaded to OneWorld", "Approved By Approver" };

                    var exceptionList = new List<string> { "Draft", "Approved", "Completed", "SubmittedForApproval", "Rejected", "AwaitingApproval",
                        "Cancelled", "Closed", "ChairmanApproved", "UploadedToOneWorld","DraftAndSubmitted" };

                    model.RemoveAll(x => exceptionList.Contains(x.CEAStatusCode));

                    //var model = modelitem.Where(m => (m.WorkflowStatus).IsNotIn(exceptionList)).ToList();
                    //var model = modelitem.Where(m => m.WorkflowStatus != "Draft" && m.WorkflowStatus != "Closed" && m.WorkflowStatus != "Closed by Approver" 
                    //    && m.WorkflowStatus != "Cancelled" && m.WorkflowStatus != "Cancelled By User" && m.WorkflowStatus != "Rejected" && m.WorkflowStatus != "Rejected By Approver" 
                    //    && m.WorkflowStatus != "Request Sent" && m.WorkflowStatus != "Uploaded to OneWorld" && m.WorkflowStatus != "Approved By Approver").ToList();

                    if (model.Count > 0)
                    {
                        requisitionList = new List<RequisitionDetail>();

                        foreach (var item in model)
                        {
                            requisitionList.Add(new RequisitionDetail()
                            {
                               
                                projectNo = item.ProjectNo,                               
                                requisitionNo = item.RequisitionNo,
                                requisitionID = item.RequisitionID,
                                requisitionDate = _converter.ConvertObjectToDate(item.RequisitionDate),
                                costCenter = item.CostCenter,
                                fiscalYear = item.FiscalYear,
                                //approvalStatus = item.ApprovalStatus,
                                statusCode = item.StatusCode,
                                assignedToEmpNo = item.AssignedToEmpNo,
                                assignedToEmpName = item.AssignedToEmpName,
                                //description = item.Description,
                                //dateofComission = item.DateofComission,
                                //amount = item.Amount,
                                //usedAmount = item.UsedAmount,
                                //createDate = item.CreateDate,
                                //createdByEmpNo = item.CreatedByEmpNo,
                                //createdByEmpName = item.CreatedByEmpName,
                                //statusHandlingCode = item.StatusHandlingCode,
                                workflowStatus = item.WorkflowStatus,
                                ceaStatusCode = item.CEAStatusCode,
                                ceaStatusDesc = item.CEAStatusDesc,
                                WorkflowID    = item.WorkflowID,
                            });
                        }
                    }
                }

                return requisitionList;
            }
            catch (SqlException sqlErr)
            {
                throw new Exception(sqlErr.Message.ToString());
            }
            catch (Exception ex)
            {
                throw;
            }
        }

        public async Task<DBTransResult?> ReassignmentRequisition(List<string> selectedRequisitionList, int? UserEmpNo, string userEmpName, string userID, string ApproverRemarks, int ReassignEmpNo,
            string ReassignEmpName, string ReassignEmpEmail, int CreatedBy,int routineSeq, bool onHold)
        {
            try
            {
                DBTransResult? dbResult = null;
                int rowsAffected = 0;

                if (selectedRequisitionList.Count() > 0)
                {
                    foreach (var item in selectedRequisitionList)
                    {
                        var requisitionDetail = new RequisitionDetail();

                        string[] reqDetails = item.Split(",");
                        string RequisitionNo = reqDetails[0].Replace("[", string.Empty);
                        int currentAssignedEmpNo = Convert.ToInt32(reqDetails[1].Replace("]", string.Empty));
                        string wfInstanceID =  Convert.ToString(reqDetails[2].Replace("]", string.Empty));

                        using (_dapperDB = new SqlConnection(_connectionString))
                        {
                            var parameters = new DynamicParameters();

                            parameters.Add("@requisitionNo", RequisitionNo);
                            parameters.Add("@reassignEmpNo", currentAssignedEmpNo, dbType: DbType.Int32);
                            parameters.Add("@reassignedToEmpNo", ReassignEmpNo, dbType: DbType.Int32);
                            parameters.Add("@approverRemarks", ApproverRemarks);
                            parameters.Add("@rowsAffected", 0, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);
                            parameters.Add("@hasError", false, dbType: DbType.Boolean, direction: ParameterDirection.InputOutput);
                            parameters.Add("@retError", 0, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);
                            parameters.Add("@retErrorDesc", string.Empty, dbType: DbType.String, direction: ParameterDirection.InputOutput);

                            //parameters.Add("@requisitionNo", RequisitionNo, DbType.String);
                            //parameters.Add("@userEmpNo", currentAssignedEmpNo, DbType.Int32);
                            //parameters.Add("@userEmpName", userEmpName, DbType.String);
                            //parameters.Add("@userID", userID, DbType.String);
                            //parameters.Add("@approverRemarks", ApproverRemarks, DbType.String);
                            //parameters.Add("@reassignEmpNo", ReassignEmpNo, DbType.Int32);
                            //parameters.Add("@CreatedBy", CreatedBy, DbType.Int32);
                            //parameters.Add("@retError", 0, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);

                            // Save to database
                            //rowsAffected = _dapperDB.Execute("Projectuser.pr_ReassignRequisition", parameters, commandType: CommandType.StoredProcedure);
                            //if (rowsAffected > 0)
                            //{
                            //    // Check for errors
                            //    int retError = parameters.Get<int>("@retError");
                            //    if (retError != GlobalSettings.DB_STATUS_OK)
                            //    {
                            //        dbResult = new DBTransResult()
                            //        {
                            //            HasError = true,
                            //            ErrorDesc = $"Unable to save reassign the requisition into the JDE system!",
                            //        };
                            //    };
                            //}
                            //else
                            //{
                            //    dbResult = new DBTransResult()
                            //    {
                            //        RowsAffected = rowsAffected,
                            //        HasError = false
                            //    };
                            //}

                            // Save to database
                            rowsAffected = _dapperDB.Execute("Projectuser.Pr_ReassignRequisition", parameters, commandType: CommandType.StoredProcedure);

                            // Check for errors
                            bool hasError = parameters.Get<bool>("@hasError");
                            if (hasError)
                            {
                                // Get the error description
                                int errorCode = parameters.Get<int>("@retError");
                                string errorDesc = parameters.Get<string>("@retErrorDesc");

                                if (!string.IsNullOrEmpty(errorDesc))
                                {
                                    dbResult = new DBTransResult()
                                    {
                                        HasError = true,
                                        ErrorID = errorCode,
                                        ErrorDesc = errorDesc
                                    };

                                   
                                }
                                else
                                {
                                    dbResult = new DBTransResult()
                                    {
                                        HasError = true,
                                        ErrorDesc = "Unable to reassign the requisition due to an unknown error that occured in the database."
                                    };
                                }
                            }
                            else
                            {

                                #region Invoke the workflow approval process
                                if (!string.IsNullOrEmpty(wfInstanceID))
                                {

                                    var wfTransResult = await this.InvokeWFReassignRequest(Convert.ToInt32(RequisitionNo), wfInstanceID, currentAssignedEmpNo, ReassignEmpNo, ReassignEmpName,
                                        ReassignEmpEmail, routineSeq, onHold, ApproverRemarks, CreatedBy, ReassignEmpName);
                                    if (wfTransResult != null && wfTransResult.HasError)
                                    {
                                        if (!string.IsNullOrEmpty(wfTransResult.ErrorDesc))
                                            throw new Exception(wfTransResult.ErrorDesc);
                                        else
                                            throw new Exception("Unable to complete the reassignment process due to an unknown error that occured within the workflow service.");
                                    }
                                }
                                #endregion

                                dbResult = new DBTransResult()
                                {
                                    RowsAffected = rowsAffected,
                                    HasError = false
                                };
                            }
                        }                   
                        
                    }
                }

                return dbResult;
            }
            catch (Exception ex) { throw; }
        }

        private async Task<DBTransResult?> InvokeWFReassignRequest(int requisitionNo, string wfInstanceID, int currentAssignedEmpNo, int reassignedEmpNo, string reassignedEmpName,
                string reassignedEmpEmail, int routineSeq, bool onHold, string reason, int reassignedBy, string reassignedName)
        {
            DBTransResult? saveResult = null;
            int retError = GlobalSettings.DB_STATUS_OK;

            try
            {
                var appSettingOptions = new AppSettingOptions();
                _config.GetSection(AppSettingOptions.AppSettings).Bind(appSettingOptions);

                GARMCO.AMS.CommonWF.BL.Entities.RequestWFItem newWFItem = new GARMCO.AMS.CommonWF.BL.Entities.RequestWFItem();

                if (this.WorkflowServiceProxy != null)
                {
                    newWFItem.RequestTypeInt = GlobalSettings.REQUEST_TYPE_CEA;
                    newWFItem.RequestTypeNo = requisitionNo;
                    newWFItem.ConnectionString = _gapConnectionString;
                    newWFItem.WorkflowDBConnectionString = _wfConnectionString;
                    newWFItem.UserActionType = GARMCO.AMS.CommonWF.BL.Enumeration.UserActionType.ReassignRequest;
                    newWFItem.ModifiedBy = reassignedBy;
                    newWFItem.ModifiedName = reassignedName;
                    newWFItem.ServiceRole = GARMCO.AMS.CommonWF.BL.Helpers.GARMCOConstants.ServiceRole.Approver;
                    newWFItem.RequestRoutineSeq = routineSeq;
                    newWFItem.RequestCurrentDistMemEmpNo = currentAssignedEmpNo;
                    newWFItem.RequestCurrentDistMemOnHold = onHold;
                    newWFItem.RequestReassignRemark = reason;
                    newWFItem.RequestNewCurrentDistMemEmpNo = reassignedEmpNo;
                    newWFItem.RequestNewCurrentDistMemEmpName = reassignedEmpName;
                    newWFItem.RequestNewCurrentDistMemEmpEmail = reassignedEmpEmail;

                    if (!string.IsNullOrEmpty(wfInstanceID))
                        newWFItem.WorkflowID = new Guid(wfInstanceID);

                    #region Approves or Rejects
                    try
                    {
                        retError = await this.WorkflowServiceProxy.RequestReassignedAsync(newWFItem);
                    }
                    catch (FaultException<ErrorDetail> Fex)
                    {
                        //throw new Exception(Fex.Detail.ErrorDescription);
                        retError = GlobalSettings.DB_WORKFLOW_ERROR;
                    }
                    #endregion

                    // Checks for error
                    if (retError != GlobalSettings.DB_STATUS_OK)
                    {
                        // Checks if the current assigned person is no longer in the current distribution list
                        if (!this.CheckAssignedDistributionMember(GlobalSettings.REQUEST_TYPE_CEA, requisitionNo, currentAssignedEmpNo,
                            Convert.ToInt32(GARMCO.AMS.CommonWF.BL.Helpers.GARMCOConstants.ServiceRole.Approver), routineSeq))
                        {
                            retError = GlobalSettings.DB_STATUS_OK;
                        }
                    }

                    if (retError == GlobalSettings.DB_STATUS_OK)
                    {
                        saveResult = new DBTransResult()
                        {
                            RowsAffected = 1,
                            HasError = false
                        };
                    }
                }
                else
                {
                    throw new Exception("Unable to initiate the workflow because the service reference is not defined. Please check whether the Workflow Service is running and accessible!");
                }

                return saveResult;
            }
            catch (Exception ex)
            {
                return new DBTransResult()
                {
                    HasError = true,
                    ErrorCode = ex.HResult.ToString(),
                    ErrorDesc = ex.Message.ToString()
                };
            }
        }

        private bool CheckAssignedDistributionMember(int? reqType, int? reqTypeNo, int? currentDistMemEmpNo, int? currentDistMemActionType, int? currentDistMemRoutineSeq)
        {
            int rowsAffected = 0;
            bool currentDistMemCurrent = false;

            try
            {
                using (_dapperDB = new SqlConnection(_gapConnectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@reqType", reqType, dbType: DbType.Int32);
                    parameters.Add("@reqTypeNo", reqTypeNo, dbType: DbType.Int32);
                    parameters.Add("@currentDistMemEmpNo", currentDistMemEmpNo, dbType: DbType.Int32);
                    parameters.Add("@currentDistMemActionType", currentDistMemActionType, dbType: DbType.Int32);
                    parameters.Add("@currentDistMemRoutineSeq", currentDistMemRoutineSeq, dbType: DbType.Int32);
                    parameters.Add("@currentDistMemCurrent", false, dbType: DbType.Boolean, direction: ParameterDirection.InputOutput);

                    // Save to database
                    rowsAffected = _dapperDB.Execute("secuser.pr_CheckAssignedDistributionMember", parameters, commandType: CommandType.StoredProcedure);

                    // Check for errors
                    currentDistMemCurrent = parameters.Get<bool>("@currentDistMemCurrent");
                }

                return currentDistMemCurrent;
            }
            catch (SqlException sqlErr)
            {
                throw new Exception(sqlErr.Message.ToString());
            }
            catch (Exception ex)
            {
                return false;
            }
        }

    }
}
