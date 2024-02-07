using CEAApp.Web.DIServices;
using CEAApp.Web.Models;
using Dapper;
using GARMCO.Common.DAL.ProcessWorkflow;
//using GARMCO.Common.DAL.Employee;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using System.Data;
using System.Data.Common;
using System.DirectoryServices;
using System.Net.Mail;
using System.ServiceModel;
using System.ServiceModel.Description;
using System.Text;
using System.Transactions;
using WFServiceProxy;

namespace CEAApp.Web.Repositories
{
    public class ProjectRepository : IProjectRepository, IADONetExtension
    {
        #region Fields
        private readonly ApplicationDbContext _db;        
        private readonly string? _connectionString;
        private readonly string? _gapConnectionString;
        private readonly string? _wfConnectionString;
        private readonly IConverterService _converter;
        private readonly IConfiguration _config;
        private IDbConnection? _dapperDB = null;

        public enum DataAccessType
        {
            Retrieve,
            Create,
            Update,
            Delete
        }
        #endregion

        #region Properties
        public ReferenceData LookupData { get; set; } = new ReferenceData();

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

        #region Constructors
        public ProjectRepository(ApplicationDbContext context, IConfiguration configuration, IConverterService converter)
        {
            _db = context;
            _connectionString = configuration.GetConnectionString("CEAConnectionString");
            _gapConnectionString = configuration.GetConnectionString("GAPConnectionString");
            _wfConnectionString = configuration.GetConnectionString("WFConnectionString");
            _converter = converter;
            _config = configuration;
        }
        #endregion

        #region LDAP Methods
        public EmployeeInfo? GetEmployeeByDomainName(string loginName, string ldapPath, string ldapUsername, string ldapPassword)
        {
            EmployeeInfo empInfo = null!;

            try
            {
                // Check the username
                if (loginName.ToLower().IndexOf("garmco\\") == -1)
                    loginName = "Garmco\\" + loginName;

                // Use the login name as the criteria
                string filter = String.Format("(&(objectCategory=user)(sAMAccountName={0}))",
                    loginName.Split(new char[] { '\\' })[1]);

                using (DirectoryEntry de = new DirectoryEntry(ldapPath))
                {
                    de.AuthenticationType = AuthenticationTypes.Secure;
                    de.Username = ldapUsername;
                    de.Password = ldapPassword;

                    // Set the attributes to show
                    string[] attribs = new string[]{"samaccountname", "mail", "displayName", "company",
                        "department", "telephonenumber", "departmentNumber" };
                    DirectorySearcher ds = new DirectorySearcher(de, filter, attribs);

                    using (SearchResultCollection src = ds.FindAll())
                    {
                        SearchResult sr = null;

                        // Check if found
                        if (src.Count > 0)
                        {
                            sr = src[0];

                            // Retrieve information
                            if (sr != null)
                            {

                                empInfo = new EmployeeInfo();

                                empInfo.EmpName = sr.Properties["displayName"][0].ToString();

                                if (sr.Properties["mail"].Count > 0)
                                    empInfo.Email = sr.Properties["mail"][0].ToString();

                                if (sr.Properties["samaccountname"].Count > 0)
                                    empInfo.UserID = sr.Properties["samaccountname"][0].ToString();

                                if (sr.Properties["company"].Count > 0)
                                    empInfo.EmpNo = _converter.ConvertObjectToInt(sr.Properties["company"][0]);

                                if (sr.Properties["departmentNumber"].Count > 0)
                                    empInfo.CostCenter = sr.Properties["departmentNumber"][0].ToString();

                                if (sr.Properties["department"].Count > 0)
                                    empInfo.CostCenterName = sr.Properties["department"][0].ToString();

                                if (sr.Properties["telephoneNumber"].Count > 0)
                                    empInfo.PhoneExt = sr.Properties["telephoneNumber"][0].ToString();
                            }
                        }
                    }
                }

                return empInfo;
            }
            catch(Exception ex)
            {
                return null;
            }
        }
        #endregion

        #region Application Security Methods
        public FormAccessEntity? GetUserFormAccess(string userFrmFormCode, string userFrmCostCenter, int userFrmEmpNo, byte mode = 1, int userFrmFormAppID = 1, string userFrmEmpName = "", string sort = "")
        {
            FormAccessEntity? userAccessData = null;

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@mode", mode);
                    parameters.Add("@userFrmFormAppID", userFrmFormAppID);
                    parameters.Add("@userFrmFormCode", userFrmFormCode);
                    parameters.Add("@userFrmCostCenter", userFrmCostCenter);
                    parameters.Add("@userFrmEmpNo", userFrmEmpNo);
                    parameters.Add("@userFrmEmpName", userFrmEmpName);
                    parameters.Add("@sort", sort);

                    var model = _dapperDB.QueryFirstOrDefault("Projectuser.pr_GetUserFormAccess", parameters, commandType: CommandType.StoredProcedure);
                    if (model != null)
                    {
                        int employeeNo = model.EmpNo;
                        userAccessData = new FormAccessEntity()
                        {
                            EmpNo = model.EmpNo,
                            EmpName = model.EmpName,
                            CostCenter = model.CostCenter,
                            FormCode = model.FormCode,
                            FormName = model.FormName,
                            FormFilename = model.FormFilename,
                            FormPublic = model.FormPublic,
                            UserFrmCRUDP = model.UserFrmCRUDP,
                            ApplicationName = model.ApplicationName
                        };
                    }
                }

                return userAccessData;
            }
            catch (Exception ex)
            {
                return null;
            }
        }
        #endregion

        #region Private Methods
        private List<FinancialDetail> GetScheduleExpenses(string requisitionNo)
        {
            List<FinancialDetail> expenseList = new List<FinancialDetail>();

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@requisitionNo", requisitionNo);

                    var model = _dapperDB.Query("Projectuser.Pr_GetScheduleOfExpenses", parameters, commandType: CommandType.StoredProcedure).ToList();
                    if (model.Count > 0)
                    {
                        foreach (var item in model)
                        {
                            expenseList.Add(new FinancialDetail()
                            {
                                RequisitionID = item.RequisitionId,
                                Amount = item.Amount,
                                FiscalYear = item.FiscalYear,
                                Quarter = item.Quarter
                            });
                        }
                    }
                    else
                    {
                        // Add dummy record
                        expenseList.Add(new FinancialDetail()
                        {
                            RequisitionID = 0,
                            Quarter = String.Empty,
                            IsDummy = true
                        });
                    }
                }

                return expenseList;
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

        private List<FileAttachment> GetFileAttachment(string requisitionNo, string costCenter = "", int fiscalYear = 0)
        {
            List<FileAttachment> attachmentList = new List<FileAttachment>();

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@requisitionNo", requisitionNo);
                    parameters.Add("@costCenter", costCenter);
                    parameters.Add("@fiscalYear", fiscalYear, DbType.Int32);

                    var model = _dapperDB.Query("Projectuser.Pr_GetRequisitionAttachment", parameters, commandType: CommandType.StoredProcedure).ToList();
                    if (model.Count > 0)
                    {
                        foreach (var item in model)
                        {
                            attachmentList.Add(new FileAttachment()
                            {
                                RequisitionAttachmentID = item.RequisitionAttachmentID,
                                RequisitionNo = item.RequisitionNo,
                                RequisitionID = item.RequisitionID,
                                FiscalYear = item.FiscalYear,
                                CostCenter = item.CostCenter,
                                AttachmentFileName = item.AttachmentFileName,
                                AttachmentDisplayName = item.AttachmentDisplayName,
                                AttachmentSize = item.AttachmentSize,
                                CreatedByEmpNo = item.CreatedByEmpNo,
                                CreatedBy = item.CreatedBy,
                                CreatedDate = item.CreatedDate,
                                Base64File = item.Base64File,
                                Base64FileExt = item.Base64FileExt
                            });
                        }
                    }
                    else
                    {
                        // Add dummy record
                        attachmentList.Add(new FileAttachment()
                        {
                            RequisitionAttachmentID = 0,
                            AttachmentFileName = String.Empty,
                            AttachmentDisplayName = String.Empty,
                            Base64File = string.Empty,
                            Base64FileExt = string.Empty,
                            CreatedBy = String.Empty,
                            IsDummy = true
                        });
                    }
                }

                return attachmentList;
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

        private DBTransResult? InsertUpdateDeleteAttachment(DataAccessType dbAccessType, List<FileAttachment>? attachmentList, decimal requisitionID = 0)
        {
            DBTransResult? dbResult = null;
            int rowsAffected = 0;

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();

                    switch (dbAccessType)
                    {
                        case DataAccessType.Create:
                            #region Insert operation

                            foreach (FileAttachment item in attachmentList!)
                            {
                                #region Call stored procedure to insert record to DB

                                // Create a dynamic object and pass a value to that object.
                                parameters = new DynamicParameters();
                                parameters.Add("@actionType", dbAccessType);
                                parameters.Add("@requisitionAttachmentID", item!.RequisitionAttachmentID, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);
                                parameters.Add("@requisitionID", item!.RequisitionID, dbType: DbType.Int32);
                                parameters.Add("@attachmentFileName", item!.AttachmentFileName);
                                parameters.Add("@attachmentDisplayName", item!.AttachmentDisplayName);
                                parameters.Add("@attachmentSize", item!.AttachmentSize, dbType: DbType.Int32);
                                parameters.Add("@userEmpNo", item!.CreatedByEmpNo);
                                parameters.Add("@userID", item!.CreatedBy);
                                parameters.Add("@base64FileExt", item!.Base64FileExt);

                                if (!string.IsNullOrWhiteSpace(item!.Base64File))
                                    parameters.Add("@base64File", item!.Base64File);

                                // Call a Stored Procedure using the db.execute method
                                rowsAffected += _dapperDB.Execute("Projectuser.Pr_RequisitionAttachments_CUD", parameters, commandType: CommandType.StoredProcedure);

                                //To get newly created ID back  
                                item.RequisitionAttachmentID = parameters.Get<Int32>("@requisitionAttachmentID");
                                #endregion
                            }

                            #region Return the DB call result
                            if (rowsAffected > 0)
                            {
                                dbResult = new DBTransResult()
                                {
                                    RowsAffected = rowsAffected,
                                    HasError = false
                                };
                            }
                            #endregion

                            break;
                        #endregion

                        case DataAccessType.Update:
                            #region Update operation

                            foreach (FileAttachment item in attachmentList!)
                            {
                                #region Call stored procedure to update existing DB record

                                // Create a dynamic object and pass a value to that object.
                                parameters = new DynamicParameters();
                                parameters.Add("@actionType", dbAccessType);
                                parameters.Add("@requisitionAttachmentID", item!.RequisitionAttachmentID, dbType: DbType.Decimal, direction: ParameterDirection.InputOutput);
                                parameters.Add("@requisitionID", item!.RequisitionID, dbType: DbType.Decimal);
                                parameters.Add("@attachmentFileName", item!.AttachmentFileName);
                                parameters.Add("@attachmentDisplayName", item!.AttachmentDisplayName);
                                parameters.Add("@attachmentSize", item!.AttachmentSize, dbType: DbType.Decimal);
                                parameters.Add("@userEmpNo", item!.CreatedByEmpNo);
                                parameters.Add("@userID", item!.CreatedBy);
                                parameters.Add("@base64FileExt", item!.Base64FileExt);

                                if (!string.IsNullOrWhiteSpace(item!.Base64File))
                                    parameters.Add("@base64File", item!.Base64File);

                                // Call a Stored Procedure using the db.execute method
                                rowsAffected += _dapperDB.Execute("Projectuser.Pr_RequisitionAttachments_CUD", parameters, commandType: CommandType.StoredProcedure);
                                #endregion
                            }

                            #region Return the DB call result
                            if (rowsAffected > 0)
                            {
                                dbResult = new DBTransResult()
                                {
                                    RowsAffected = rowsAffected,
                                    HasError = false
                                };
                            }
                            #endregion

                            break;
                        #endregion

                        case DataAccessType.Delete:
                            #region Delete operation
                            if (requisitionID > 0)
                            {
                                parameters = new DynamicParameters();
                                parameters.Add("@actionType", dbAccessType);
                                parameters.Add("@requisitionAttachmentID", 0, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);
                                parameters.Add("@requisitionID", requisitionID);

                                rowsAffected = _dapperDB.Execute("Projectuser.Pr_RequisitionAttachments_CUD", parameters, commandType: CommandType.StoredProcedure);
                                if (rowsAffected > 0)
                                {
                                    dbResult = new DBTransResult()
                                    {
                                        RowsAffected = rowsAffected,
                                        HasError = false
                                    };
                                }
                            }
                            break;
                            #endregion
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
                return new DBTransResult()
                {
                    HasError = true,
                    ErrorCode = ex.HResult.ToString(),
                    ErrorDesc = ex.Message.ToString()
                };
            }
        }

        private DBTransResult? InsertUpdateDeleteExpenses(DataAccessType dbAccessType, List<FinancialDetail>? expenseList, decimal requisitionID = 0)
        {
            DBTransResult? dbResult = null;
            int rowsAffected = 0;

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();

                    switch (dbAccessType)
                    {
                        case DataAccessType.Create:
                            #region Insert operation

                            foreach (FinancialDetail item in expenseList!)
                            {
                                #region Call stored procedure to insert record to DB

                                // Create a dynamic object and pass a value to that object.
                                parameters = new DynamicParameters();
                                parameters.Add("@actionType", dbAccessType);
                                parameters.Add("@expenseID", item!.ExpenseID, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);
                                parameters.Add("@requisitionID", item!.RequisitionID, dbType: DbType.Int32);
                                parameters.Add("@amount", item!.Amount);
                                parameters.Add("@fiscalYear", item!.FiscalYear, dbType: DbType.Int32);
                                parameters.Add("@quarter", item!.Quarter);

                                // Call a Stored Procedure using the db.execute method
                                rowsAffected += _dapperDB.Execute("Projectuser.Pr_Expense_CUD", parameters, commandType: CommandType.StoredProcedure);

                                //To get newly created ID back  
                                item.ExpenseID = parameters.Get<Int32>("@expenseID");
                                #endregion
                            }

                            #region Return the DB call result
                            if (rowsAffected > 0)
                            {
                                dbResult = new DBTransResult()
                                {
                                    RowsAffected = rowsAffected,
                                    HasError = false
                                };
                            }
                            #endregion

                            break;
                        #endregion

                        case DataAccessType.Update:
                            #region Update operation

                            foreach (FinancialDetail item in expenseList!)
                            {
                                #region Call stored procedure to update existing DB record

                                // Create a dynamic object and pass a value to that object.
                                parameters = new DynamicParameters();
                                parameters.Add("@actionType", dbAccessType);
                                parameters.Add("@expenseID", item!.ExpenseID, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);
                                parameters.Add("@requisitionID", item!.RequisitionID, dbType: DbType.Int32);
                                parameters.Add("@amount", item!.Amount);
                                parameters.Add("@fiscalYear", item!.FiscalYear, dbType: DbType.Int32);
                                parameters.Add("@quarter", item!.Quarter);

                                // Call a Stored Procedure using the db.execute method
                                rowsAffected += _dapperDB.Execute("Projectuser.Pr_Expense_CUD", parameters, commandType: CommandType.StoredProcedure);
                                #endregion
                            }

                            #region Return the DB call result
                            if (rowsAffected > 0)
                            {
                                dbResult = new DBTransResult()
                                {
                                    RowsAffected = rowsAffected,
                                    HasError = false
                                };
                            }
                            #endregion

                            break;
                        #endregion

                        case DataAccessType.Delete:
                            #region Delete operation
                            if (requisitionID > 0)
                            {
                                parameters = new DynamicParameters();
                                parameters.Add("@actionType", dbAccessType);
                                parameters.Add("@expenseID", 0, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);
                                parameters.Add("@requisitionID", requisitionID);

                                rowsAffected = _dapperDB.Execute("Projectuser.Pr_Expense_CUD", parameters, commandType: CommandType.StoredProcedure);
                                if (rowsAffected > 0)
                                {
                                    dbResult = new DBTransResult()
                                    {
                                        RowsAffected = rowsAffected,
                                        HasError = false
                                    };
                                }
                            }
                            break;
                            #endregion
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
                return new DBTransResult()
                {
                    HasError = true,
                    ErrorCode = ex.HResult.ToString(),
                    ErrorDesc = ex.Message.ToString()
                };
            }
        }

        private DBTransResult? ConfigureApprovers(int requisitionID)
        {
            DBTransResult? dbResult = null;
            int rowsAffected = 0;

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@requisitionID", requisitionID, dbType: DbType.Int32);

                    // Save to database
                    rowsAffected += _dapperDB.Execute("Projectuser.Pr_ConfigureCEAApprovers", parameters, commandType: CommandType.StoredProcedure);

                    if (rowsAffected > 0)
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
                return new DBTransResult()
                {
                    HasError = true,
                    ErrorCode = ex.HResult.ToString(),
                    ErrorDesc = ex.Message.ToString()
                };
            }
        }

        private DBTransResult? SetRequisitionStatus(int requisitionID)
        {
            DBTransResult? dbResult = null;
            int rowsAffected = 0;
            int nextSequenceID = 0;

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@requisitionID", requisitionID, dbType: DbType.Int32);
                    parameters.Add("@nextSequence", 0, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);

                    // Save to database
                    rowsAffected += _dapperDB.Execute("Projectuser.Pr_SetRequisitionStatus", parameters, commandType: CommandType.StoredProcedure);

                    //Get the next sequence
                    nextSequenceID = parameters.Get<Int32>("@nextSequence");

                    if (rowsAffected > 0)
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
                return new DBTransResult()
                {
                    HasError = true,
                    ErrorCode = ex.HResult.ToString(),
                    ErrorDesc = ex.Message.ToString()
                };
            }
        }

        private DBTransResult? SaveRequisitionToOneWorld(int requisitionID, DateTime commisionDate, string description, string projectNo, string userID, string workStationID)
        {
            DBTransResult? dbResult = null;
            int rowsAffected = 0;

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@requisitionID", requisitionID, dbType: DbType.Int32);
                    parameters.Add("@commisionDate", commisionDate, dbType: DbType.DateTime);
                    parameters.Add("@description", description);
                    parameters.Add("@projectNo", projectNo);
                    parameters.Add("@userID", userID);
                    parameters.Add("@workStationID", workStationID);
                    parameters.Add("@rowsAffected", 0, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);
                    parameters.Add("@hasError", false, dbType: DbType.Boolean, direction: ParameterDirection.InputOutput);
                    parameters.Add("@retError", 0, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);
                    parameters.Add("@retErrorDesc", string.Empty, dbType: DbType.String, direction: ParameterDirection.InputOutput);

                    // Save to database
                    rowsAffected = _dapperDB.Execute("Projectuser.Pr_SaveCEADataToOneWorld", parameters, commandType: CommandType.StoredProcedure);
                    if (rowsAffected > 0)
                    {
                        // Check for errors
                        bool hasError = parameters.Get<bool>("@hasError");
                        if (hasError)
                        {
                            // Get the error description
                            string errorDesc = parameters.Get<string>("@retErrorDesc");
                            if (!string.IsNullOrEmpty(errorDesc))
                                throw new Exception(errorDesc);
                            else
                                throw new Exception("Unable to save CEA information into the JDE system!");
                        }
                        else
                        {
                            dbResult = new DBTransResult()
                            {
                                RowsAffected = rowsAffected,
                                HasError = false
                            };
                        }
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
                return new DBTransResult()
                {
                    HasError = true,
                    ErrorCode = ex.HResult.ToString(),
                    ErrorDesc = ex.Message.ToString()
                };
            }
        }

        private List<CEAAdminInfo> GetCEAAdministrators(string ceaNo)
        {
            List<CEAAdminInfo> employeeList = new List<CEAAdminInfo>();

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@ceaNo", ceaNo);

                    var model = _dapperDB.Query("Projectuser.Pr_GetCEAAdministratorEmailList", parameters, commandType: CommandType.StoredProcedure).ToList();
                    if (model.Count > 0)
                    {
                        employeeList = new List<CEAAdminInfo>();

                        foreach (var item in model)
                        {
                            employeeList.Add(new CEAAdminInfo()
                            {
                                RequisitionNo = Convert.ToInt32(ceaNo),
                                CEADescription = item.CEADescription,
                                EmpNo = item.EmpNo,
                                EmpName = item.EmpName,
                                Email = item.EmpEmail
                            });
                        }
                    }
                }

                return employeeList;
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

        private List<CEAAdminInfo> GetCostCenterApprovers(string ceaNo)
        {
            List<CEAAdminInfo> employeeList = new List<CEAAdminInfo>();

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@ceaNo", ceaNo);

                    var model = _dapperDB.Query("Projectuser.Pr_GetCostCenterEmailList", parameters, commandType: CommandType.StoredProcedure).ToList();
                    if (model.Count > 0)
                    {
                        employeeList = new List<CEAAdminInfo>();

                        foreach (var item in model)
                        {
                            employeeList.Add(new CEAAdminInfo()
                            {
                                RequisitionNo = Convert.ToInt32(ceaNo),
                                CEADescription = item.CEADescription,
                                EmpNo = item.EmpNo,
                                EmpName = item.EmpName,
                                Email = item.EmpEmail
                            });
                        }
                    }
                }

                return employeeList;
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

        private List<CEAAdminInfo> GetEquipmentAdmin(string ceaNo)
        {
            List<CEAAdminInfo> employeeList = new List<CEAAdminInfo>();

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@ceaNo", ceaNo);

                    var model = _dapperDB.Query("Projectuser.Pr_GetEquipmentNoAssigners", parameters, commandType: CommandType.StoredProcedure).ToList();
                    if (model.Count > 0)
                    {
                        employeeList = new List<CEAAdminInfo>();

                        foreach (var item in model)
                        {
                            employeeList.Add(new CEAAdminInfo()
                            {
                                RequisitionNo = Convert.ToInt32(ceaNo),
                                CEADescription = item.CEADescription,
                                EmpNo = item.EmpNo,
                                EmpName = item.EmpName,
                                Email = item.EmpEmail
                            });
                        }
                    }
                }

                return employeeList;
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
        #endregion

        #region Public Methods
        public async Task<ReferenceData> GetLookupTable(string objectCode = "")
        {
            ReferenceData model = null!;

            try
            {
                List<UserdefinedCode> fiscalYearList = new List<UserdefinedCode>();
                List<UserdefinedCode> costCenterList = new List<UserdefinedCode>();
                List<UserdefinedCode> projectStatusList = new List<UserdefinedCode>();
                List<UserdefinedCode> expenditureTypeList = new List<UserdefinedCode>();
                List<UserdefinedCode> expenseTypeList = new List<UserdefinedCode>();
                List<UserdefinedCode> reqStatusList = new List<UserdefinedCode>();
                List<UserdefinedCode> approvalTypeList = new List<UserdefinedCode>();
                List<UserdefinedCode> itemTypeList = new List<UserdefinedCode>();
                List<UserdefinedCode> plantLocationList = new List<UserdefinedCode>();
                List<UserdefinedCode> expenseYearList = new List<UserdefinedCode>();
                List<UserdefinedCode> expenseQuarterList = new List<UserdefinedCode>();
                List<EmployeeDetail> ceaAdminList = new List<EmployeeDetail>();
                List<EmployeeInfo> employeeList = new List<EmployeeInfo>();
                DbCommand cmd;
                DbDataReader reader;

                string sql = "EXEC Projectuser.Pr_GetLookupTable @objectCode";

                // Build the command object
                cmd = _db.Database.GetDbConnection().CreateCommand();
                cmd.CommandText = sql;

                // Create parameters
                cmd.Parameters.Add(new SqlParameter { ParameterName = "@objectCode", SqlDbType = SqlDbType.VarChar, Size = 20, Value = objectCode });

                // Open database connection
                await _db.Database.OpenConnectionAsync();

                // Create a DataReader  
                reader = await cmd.ExecuteReaderAsync(CommandBehavior.CloseConnection);

                if (string.IsNullOrEmpty(objectCode))
                {
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

                    #region Get the cost center list
                    // Advance to the next result set  
                    reader.NextResult();

                    while (await reader.ReadAsync())
                    {
                        costCenterList.Add(new UserdefinedCode
                        {
                            UDCValue = _converter.ConvertObjectToString(reader["CostCenter"]),
                            UDCDescription = _converter.ConvertObjectToString(reader["CostCenterName"])
                        });
                    }
                    #endregion

                    #region Get the Project Status list
                    // Advance to the next result set  
                    reader.NextResult();

                    while (await reader.ReadAsync())
                    {
                        projectStatusList.Add(new UserdefinedCode
                        {
                            UDCValue = _converter.ConvertObjectToString(reader["StatusCode"]),
                            UDCDescription = _converter.ConvertObjectToString(reader["ApprovalStatus"])
                        });
                    }
                    #endregion

                    #region Get the Expenditure Type list
                    // Advance to the next result set  
                    reader.NextResult();

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

                    #region Get Requisition Status
                    // Advance to the next result set  
                    reader.NextResult();

                    while (await reader.ReadAsync())
                    {
                        reqStatusList.Add(new UserdefinedCode
                        {
                            UDCValue = _converter.ConvertObjectToString(reader["StatusCode"]),
                            UDCDescription = _converter.ConvertObjectToString(reader["StatusDescription"])
                        });
                    }
                #endregion

                    #region Pending Approval Types
                    // Advance to the next result set  
                    reader.NextResult();

                    while (await reader.ReadAsync())
                    {
                        approvalTypeList.Add(new UserdefinedCode
                        {
                            UDCValue = _converter.ConvertObjectToString(reader["ApprovalCode"]),
                            UDCDescription = _converter.ConvertObjectToString(reader["ApprovalDescription"])
                        });
                    }
                    #endregion

                    // Initialize the model properties
                    model = new ReferenceData()
                    {
                        FiscalYearList = fiscalYearList,
                        CostCenterList = costCenterList,
                        ProjectStatusList = projectStatusList,
                        ExpenditureTypeList = expenditureTypeList,
                        ExpenseTypeList = expenseTypeList,
                        RequisitionStatusList = reqStatusList,
                        ApprovalTypeList = approvalTypeList
                    };
                }
                else
                {
                    switch (objectCode)
                    {
                        case "CEAREQUISITION":
                            #region Get the datasource for all comboboxes in CEA Requisition form                            
                            
                            #region Get Cost Centers
                            while (await reader.ReadAsync())
                            {
                                costCenterList.Add(new UserdefinedCode
                                {
                                    UDCValue = _converter.ConvertObjectToString(reader["CostCenter"]),
                                    UDCDescription = _converter.ConvertObjectToString(reader["CostCenterName"])
                                });
                            }
                            #endregion

                            #region Get Fiscal Years
                            // Advance to the next result set  
                            reader.NextResult();

                            while (await reader.ReadAsync())
                            {
                                fiscalYearList.Add(new UserdefinedCode
                                {
                                    UDCValue = _converter.ConvertObjectToString(reader["FiscalYearValue"]),
                                    UDCDescription = _converter.ConvertObjectToString(reader["FiscalYearDesc"])
                                });
                            }
                            #endregion

                            #region Get Item Types 
                            // Advance to the next result set  
                            reader.NextResult();

                            while (await reader.ReadAsync())
                            {
                                itemTypeList.Add(new UserdefinedCode
                                {
                                    UDCValue = _converter.ConvertObjectToString(reader["RequisitionCategoryCode"]),
                                    UDCDescription = _converter.ConvertObjectToString(reader["RequisitionCategory"])
                                });
                            }
                            #endregion

                            #region Get Expenditure Types
                            // Advance to the next result set  
                            reader.NextResult();

                            while (await reader.ReadAsync())
                            {
                                expenditureTypeList.Add(new UserdefinedCode
                                {
                                    UDCValue = _converter.ConvertObjectToString(reader["ExpenditureTypeCode"]),
                                    UDCDescription = _converter.ConvertObjectToString(reader["ExpenditureTypeDesc"])
                                });
                            }
                            #endregion

                            #region Get Plant Locations
                            // Advance to the next result set  
                            reader.NextResult();

                            while (await reader.ReadAsync())
                            {
                                plantLocationList.Add(new UserdefinedCode
                                {
                                    UDCValue = _converter.ConvertObjectToString(reader["CostCenter"]),
                                    UDCDescription = _converter.ConvertObjectToString(reader["CostCenterName"])
                                });
                            }
                            #endregion

                            #region Get Fiscal Year for Schedule of Expense
                            // Advance to the next result set  
                            reader.NextResult();

                            while (await reader.ReadAsync())
                            {
                                expenseYearList.Add(new UserdefinedCode
                                {
                                    UDCValue = _converter.ConvertObjectToString(reader["ExpenseYear"]),
                                    UDCDescription = _converter.ConvertObjectToString(reader["ExpenseYear"])
                                });
                            }
                            #endregion

                            #region Get Quarters for Schedule of Expense
                            // Advance to the next result set  
                            reader.NextResult();

                            while (await reader.ReadAsync())
                            {
                                expenseQuarterList.Add(new UserdefinedCode
                                {
                                    UDCValue = _converter.ConvertObjectToString(reader["ExpenseQuarter"]),
                                    UDCDescription = _converter.ConvertObjectToString(reader["ExpenseQuarter"])
                                });
                            }
                            #endregion

                            #region Get CEA Administrators
                            // Advance to the next result set  
                            reader.NextResult();

                            while (await reader.ReadAsync())
                            {
                                ceaAdminList.Add(new EmployeeDetail
                                {
                                    empNo = _converter.ConvertObjectToInt(reader["EmpNo"]),
                                    empName = _converter.ConvertObjectToString(reader["EmpName"])
                                });
                            }
                            #endregion

                            // Initialize the model properties
                            model = new ReferenceData()
                            {
                                CostCenterList = costCenterList,
                                FiscalYearList = fiscalYearList,
                                ItemTypeList = itemTypeList,
                                ExpenditureTypeList = expenditureTypeList,
                                PlantLocationList = plantLocationList,
                                ExpenseYearList = expenseYearList,
                                ExpenseQuarterList = expenseQuarterList,
                                CEAAdminList = ceaAdminList
                            };
                            #endregion
                            break;
                    }
                }

                // Close reader and database connection
                await reader.CloseAsync();

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

        public List<ProjectDetail> GetProjectList(int fiscalYear = 0, string projectNo = "", string costCenter = "", string expenditureType = "", 
            string statusCode = "", string keywords = "")
        {
            List<ProjectDetail> projectList = null;

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@fiscalYear", fiscalYear, DbType.Int32);
                    parameters.Add("@projectNo", projectNo, DbType.String, ParameterDirection.Input, 12);
                    parameters.Add("@costCenter", costCenter, DbType.String, ParameterDirection.Input, 12);
                    parameters.Add("@expenditureType", expenditureType, DbType.String, ParameterDirection.Input, 10);
                    parameters.Add("@statusCode", statusCode, DbType.String, ParameterDirection.Input, 50);
                    parameters.Add("@keywords", keywords, DbType.String, ParameterDirection.Input, 50);
                    
                    var model = _dapperDB.Query("Projectuser.Pr_GetProjectList", parameters, commandType: CommandType.StoredProcedure).ToList();
                    if (model.Count > 0)
                    {
                        projectList = new List<ProjectDetail>();

                        foreach (var item in model)
                        {
                            projectList.Add(new ProjectDetail()
                            {
                                projectID = item.ProjectID,
                                projectNo = item.ProjectNo,
                                projectDate = item.ProjectDate,
                                companyCode = item.CompanyCode,
                                costCenter = item.CostCenter,
                                expenditureType = item.ExpenditureType,
                                description = item.Description,
                                detailDescription = item.DetailDescription,
                                accountCode = item.AccountCode,
                                projectType = item.ProjectType,
                                fiscalYear = item.FiscalYear,
                                projectAmount = item.ProjectAmount,
                                projectStatusID = item.ProjectStatusID,
                                projectStatus = item.ProjectStatus,
                                projectStatusDesc = item.ProjectStatusDesc,
                                createBy = item.CreateBy,
                                createDate = item.CreatedDate
                            });
                        }
                    }
                }

                return projectList;
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

        public ProjectInfo GetProjectDetail(string projectNo)
        {
            ProjectInfo projectDetail = null!;

            try
            {
                #region Fetch data using Dapper
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@projectNo", projectNo, DbType.String, ParameterDirection.Input, 12);

                    var model = _dapperDB.QueryFirstOrDefault<ProjectInfo>("Projectuser.Pr_GetProjectDetail", parameters, commandType: CommandType.StoredProcedure);
                    if (model != null)
                    {
                        projectDetail = new ProjectInfo();
                        projectDetail = model ;
                    }
                }
                #endregion

                #region Dapper using ExecuteReader
                //using (_dapperDB = new SqlConnection(_connectionString))
                //{
                //    var reader = _dapperDB.ExecuteReader("Projectuser.Pr_GetProjectDetail", new { projectNo = projectNo }, commandType: CommandType.StoredProcedure);

                //    DataTable table = new DataTable();
                //    table.Load(reader);
                //}
                #endregion

                #region Fetch data using EF Core
                //string sql = "EXEC Projectuser.Pr_GetProjectDetail @projectNo";

                //List<SqlParameter> parms = new List<SqlParameter>
                //{
                //    // Create parameters
                //    new SqlParameter { ParameterName = "@projectNo", SqlDbType = SqlDbType.VarChar, Size = 12, Value = projectNo },
                //};

                //var list = _db.ProjectDetail
                //    .FromSqlRaw<ProjectInfo>(sql, parms.ToArray())
                //    .AsNoTracking()
                //    .ToList();
                //if (list != null)
                //{
                //    //costCenterList.AddRange(list);
                //}
                #endregion

                return projectDetail;
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

        public List<RequisitionDetail> GetRequisitionList(string projectNo = "", string requisitionNo = "", string expenditureType = "", int fiscalYear = 0, string statusCode = "", 
            string costCenter = "", int empNo = 0, string approvalType = "", string keywords = "", DateTime? startDate = null, DateTime? endDate = null)
        {
            List<RequisitionDetail> requisitionList = new List<RequisitionDetail>();

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@projectNo", projectNo, DbType.String, ParameterDirection.Input, 12);
                    parameters.Add("@requisitionNo", requisitionNo, DbType.String, ParameterDirection.Input, 12);
                    parameters.Add("@expenditureType", expenditureType, DbType.String, ParameterDirection.Input, 12);
                    parameters.Add("@fiscalYear", fiscalYear, DbType.Int32);
                    parameters.Add("@statusCode", statusCode, DbType.String, ParameterDirection.Input, 50);
                    parameters.Add("@costCenter", costCenter, DbType.String, ParameterDirection.Input, 12);
                    parameters.Add("@empNo", empNo, DbType.Int32);
                    parameters.Add("@approvalType", approvalType, DbType.String, ParameterDirection.Input, 10);
                    parameters.Add("@keywords", keywords, DbType.String, ParameterDirection.Input, 50);
                    parameters.Add("@startDate", startDate, DbType.DateTime);
                    parameters.Add("@endDate", endDate, DbType.DateTime);

                    var model = _dapperDB.Query("Projectuser.Pr_SearchRequisition", parameters, commandType: CommandType.StoredProcedure).ToList();
                    //var model = _dapperDB.Query("Projectuser.Pr_SearchRequisition", parameters, commandType: CommandType.StoredProcedure, commandTimeout: 180).ToList();
                    if (model.Count > 0)
                    {
                        requisitionList = new List<RequisitionDetail>();

                        foreach (var item in model)
                        {
                            requisitionList.Add(new RequisitionDetail()
                            {
                                requisitionID = item.RequisitionID,                                
                                projectNo = item.ProjectNo,
                                fiscalYear = item.FiscalYear,
                                requisitionNo = item.RequisitionNo,
                                requisitionDate = item.RequisitionDate,
                                description = item.Description,
                                dateofComission = item.DateofComission,
                                amount = item.Amount,
                                usedAmount = item.UsedAmount,                                                                
                                costCenter = item.CostCenter,
                                createDate = item.CreateDate,
                                createdByEmpNo = item.CreatedByEmpNo,
                                createdByEmpName = item.CreatedByEmpName,
                                approvalStatus = item.ApprovalStatus,
                                statusCode = item.StatusCode,
                                statusHandlingCode = item.StatusHandlingCode,
                                workflowStatus = item.WorkflowStatus,
                                assignedToEmpNo = item.AssignedToEmpNo,
                                assignedToEmpName = item.AssignedToEmpName,
                                useNewWF = item.UseNewWF
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

        public async Task<List<RequisitionDetail>> GetRequisitionListNew(string projectNo = "", string requisitionNo = "", string expenditureType = "", int fiscalYear = 0, string statusCode = "",
            string costCenter = "", int empNo = 0, string approvalType = "", string keywords = "", DateTime? startDate = null, DateTime? endDate = null, byte createdByType = 0)
        {
            List<RequisitionDetail> requisitionList = new List<RequisitionDetail>();

            try
            {
                #region Old code for passing parameters to the stored procedure
                //string sql = "EXEC Projectuser.Pr_SearchRequisition @projectNo, @requisitionNo, @expenditureType, @fiscalYear, @statusCode, @costCenter, @empNo, @approvalType, @keywords, @startDate, @endDate;";

                // Create parameters
                //List<SqlParameter> parms = new List<SqlParameter>
                //{
                //    new SqlParameter { ParameterName = "@projectNo", SqlDbType = SqlDbType.VarChar, Size = 12, Value = projectNo  },
                //    new SqlParameter { ParameterName = "@requisitionNo", SqlDbType = SqlDbType.VarChar, Size = 12, Value = requisitionNo  },
                //    new SqlParameter { ParameterName = "@expenditureType", SqlDbType = SqlDbType.VarChar, Size = 10, Value = expenditureType  },
                //    new SqlParameter { ParameterName = "@fiscalYear", SqlDbType = SqlDbType.SmallInt, Value = fiscalYear  },
                //    new SqlParameter { ParameterName = "@statusCode", SqlDbType = SqlDbType.VarChar, Size = 50, Value = statusCode  },
                //    new SqlParameter { ParameterName = "@costCenter", SqlDbType = SqlDbType.VarChar, Size = 12, Value = costCenter  },
                //    new SqlParameter { ParameterName = "@empNo", SqlDbType = SqlDbType.Int, Value = fiscalYear  },
                //    new SqlParameter { ParameterName = "@approvalType", SqlDbType = SqlDbType.VarChar, Size = 10, Value = approvalType  },
                //    new SqlParameter { ParameterName = "@keywords", SqlDbType = SqlDbType.VarChar, Size = 50, Value = keywords  },
                //    new SqlParameter { ParameterName = "@startDate", SqlDbType = SqlDbType.DateTime, Value = startDate  },
                //    new SqlParameter { ParameterName = "@endDate", SqlDbType = SqlDbType.DateTime, Value = endDate  }
                //};

                //var paramProjectNo = new SqlParameter("@projectNo", System.Data.SqlDbType.VarChar, 12);
                //var paramRequisitionNo = new SqlParameter("@requisitionNo", System.Data.SqlDbType.VarChar, 12);
                //var paramExpenditureType = new SqlParameter("@expenditureType", System.Data.SqlDbType.VarChar, 10);
                //var paramFiscalYear = new SqlParameter("@fiscalYear", System.Data.SqlDbType.SmallInt);
                //var paramStatusCode = new SqlParameter("@statusCode", System.Data.SqlDbType.VarChar, 50);
                //var paramCostCenter = new SqlParameter("@costCenter", System.Data.SqlDbType.VarChar, 12);
                //var paramEmpNo = new SqlParameter("@empNo", System.Data.SqlDbType.Int);
                //var paramApprovalType = new SqlParameter("@approvalType", System.Data.SqlDbType.VarChar, 10);
                //var paramKeywords = new SqlParameter("@keywords", System.Data.SqlDbType.VarChar, 50);
                //var paramStartDate = new SqlParameter("@startDate", System.Data.SqlDbType.DateTime);
                //var paramEndDate = new SqlParameter("@endDate", System.Data.SqlDbType.DateTime);

                //paramProjectNo.Value = projectNo;
                //paramRequisitionNo.Value = requisitionNo; 
                //paramExpenditureType.Value = expenditureType;
                //paramFiscalYear.Value = fiscalYear;
                //paramStatusCode.Value = statusCode;
                //paramCostCenter.Value = costCenter;
                //paramEmpNo.Value = empNo;
                //paramApprovalType.Value = approvalType;
                //paramKeywords.Value = keywords;
                //paramStartDate.Value = startDate;
                //paramEndDate.Value = endDate;

                //var model = await _db.RequisitionDetailList
                //    .FromSqlRaw(sql, parms.ToArray())
                //    .AsNoTracking()
                //    .ToListAsync();
                #endregion

                var model = await _db.RequisitionDetailList
                    .FromSqlInterpolated($"EXEC Projectuser.Pr_SearchRequisition {projectNo}, {requisitionNo}, {expenditureType}, {fiscalYear}, {statusCode}, {costCenter}, {empNo}, {approvalType}, {keywords}, {startDate}, {endDate}, {createdByType}")
                    .AsNoTracking()
                    .ToListAsync();

                return model;
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

        public async Task<DBTransResult> InsertUpdateDeleteProject(DataAccessType actionType, ProjectInfo project)
        {
            DBTransResult dbResult = new DBTransResult(){ HasError = false};

            try
            {
                switch(actionType)
                {
                    case DataAccessType.Update:
                        #region Perform update operation
                        var recordToUpdate = _db.Projects.Where(a => a.ProjectId == project.ProjectID).FirstOrDefault();
                        if (recordToUpdate != null)
                        {
                            recordToUpdate.FiscalYear = _converter.ConvertObjectToShort(project.FiscalYear);
                            recordToUpdate.ExpectedProjectDate = Convert.ToDateTime(project.ExpectedProjectDate);
                            recordToUpdate.CostCenter = project.CostCenter!;
                            recordToUpdate.ExpenditureType = project.ExpenditureType!;
                            recordToUpdate.Description = project.Description;
                            recordToUpdate.DetailDescription = project.DetailDescription;
                            recordToUpdate.ProjectAmount = project.ProjectAmount;
                            recordToUpdate.AccountCode = project.AccountCode;
                            recordToUpdate.ObjectCode = project.ObjectCode;
                            recordToUpdate.SubjectCode = project.SubjectCode;

                            // Commit the changes
                            await _db.SaveChangesAsync();

                            dbResult = new DBTransResult(){RowsAffected = 1};
                        }
                        break;
                        #endregion

                    case DataAccessType.Delete:
                        #region Perform delete operation
                        var recordToDelete = await _db.Projects.FindAsync(project.ProjectID);
                        if (recordToDelete != null)
                        {
                            _db.Projects.Remove(recordToDelete);
                            await _db.SaveChangesAsync();

                            dbResult = new DBTransResult() { RowsAffected = 1 };
                        }
                        break;
                        #endregion
                }

                return dbResult;
            }
            catch (SqlException sqlErr)
            {
                throw new Exception(sqlErr.Message.ToString());
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

        public List<EmployeeInfo> GetEmployeeList(int empNo = 0)
        {
            List<EmployeeInfo> employeeList = new List<EmployeeInfo>();

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@empNo", empNo, DbType.Int32);
                    var model = _dapperDB.Query("Projectuser.Pr_GetEmployeeList", parameters, commandType: CommandType.StoredProcedure).ToList();

                    if (model.Count > 0)
                    {
                        employeeList = new List<EmployeeInfo>();

                        foreach (var item in model)
                        {
                            employeeList.Add(new EmployeeInfo()
                            {
                                EmpNo = item.EmpNo,
                                EmpName = item.EmpName,
                                CostCenter = item.CostCenter,
                                PayGrade = item.PayGrade,
                                Position = item.Position,
                                Email = item.EmpEmail
                            });
                        }
                    }
                }

                return employeeList;
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

        public async Task<List<RequisitionStatus>> GetRequisitionStatus(int requisitionID)
        {
            try
            {
                #region Fetch data using EF Core
                string sql = "EXEC Projectuser.Pr_GetRequisitionStatus @requisitionID";

                // Create parameters
                List<SqlParameter> parms = new List<SqlParameter>
                {
                    new SqlParameter { ParameterName = "@requisitionID", SqlDbType = SqlDbType.Int, Value = requisitionID },
                };

                var model = await _db.RequestStatusDetail
                    .FromSqlRaw(sql, parms.ToArray())
                    .AsNoTracking()
                    .ToListAsync();

                return model;
                #endregion
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

        public async Task<List<ExpenseDetail>> GetExpenseList(string requisitionNo)
        {
            try
            {
                string sql = "EXEC Projectuser.Pr_GetExpenses @requisitionNo";

                // Create parameters
                List<SqlParameter> parms = new List<SqlParameter>
                {
                    new SqlParameter { ParameterName = "@requisitionNo", SqlDbType = SqlDbType.VarChar, Value = requisitionNo },
                };

                var model = await _db.ExpenseList
                    .FromSqlRaw(sql, parms.ToArray())
                    .AsNoTracking()
                    .ToListAsync();

                return model;
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

        public EmployeeDetail GetEmployeeInfo(string userID)
        {
            EmployeeDetail empInfo = null!;

            try
            {
                //int? retError = 0;
                //string errorMsg = String.Empty;
                //EmployeeBLL empBLL = new EmployeeBLL();

                //var model = empBLL.GetEmployeeInfo(userID, ref retError, ref errorMsg);
                //if (model != null)
                //{
                //    //empInfo = new EmployeeDetail()
                //    //{
                //    //    EmpNo = _converter.ConvertObjectToInt(model.EmployeeNo),
                //    //    EmpName = _converter.ConvertObjectToString(model.FullName),
                //    //    Email = _converter.ConvertObjectToString(model.Email),
                //    //    UserID = _converter.ConvertObjectToString(model.Username),
                //    //    CostCenter = _converter.ConvertObjectToString(model.CostCenter),
                //    //    CostCenterName = _converter.ConvertObjectToString(model.CostCenterName),
                //    //    SupervisorEmpNo = _converter.ConvertObjectToInt(model.SupervisorEmpNo),
                //    //    SupervisorEmpName = _converter.ConvertObjectToString(model.SupervisorEmpName),
                //    //    SuperintendentEmpNo = _converter.ConvertObjectToInt(model.SuperintendentEmpNo),
                //    //    SuperintendentEmpName = _converter.ConvertObjectToString(model.SuperintendentEmpName),
                //    //    ManagerEmpNo = _converter.ConvertObjectToInt(model.ManagerEmpNo),
                //    //    ManagerEmpName = _converter.ConvertObjectToString(model.ManagerEmpName),
                //    //    Position = _converter.ConvertObjectToString(model.PositionDesc),
                //    //    PayGrade = _converter.ConvertObjectToInt(model.PayGrade)
                //    //};
                //}

                return empInfo;
            }
            catch (Exception err)
            {
                throw;
            }
        }

        public List<EmployeeDetail> SearchEmployee(int? empNo, string? empName, string? costCenter)
        {
            List<EmployeeDetail> employeeList = new List<EmployeeDetail>();

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@empNo", empNo, DbType.Int32);
                    parameters.Add("@empName", empName);
                    parameters.Add("@costCenter", costCenter);

                    var model = _dapperDB.Query("Projectuser.Pr_SearchEmployee", parameters, commandType: CommandType.StoredProcedure).ToList();
                    if (model.Count > 0)
                    {
                        employeeList = new List<EmployeeDetail>();

                        foreach (var item in model)
                        {
                            employeeList.Add(new EmployeeDetail()
                            {
                                empNo = item.EmpNo,
                                empName = item.EmpName,
                                costCenter = item.CostCenter,
                                costCenterName = item.CostCenterName,
                                payGrade = item.PayGrade,
                                payStatus = item.PayStatus,
                                dateJoined = item.DateJoined,
                                supervisorEmpNo = item.SupervisorEmpNo,
                                supervisorEmpName = item.SupervisorEmpName,
                                email = item.Email
                            });
                        }
                    }
                }

                return employeeList;
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

        public CEARequest? GetRequisitionDetail(string requisitionNo)
        {
            CEARequest? requestDetail = null;

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@requisitionNo", requisitionNo.Trim(), DbType.String, ParameterDirection.Input, 50);

                    var model = _dapperDB.QueryFirstOrDefault<CEARequest>("Projectuser.Pr_GetRequisitionDetail", parameters, commandType: CommandType.StoredProcedure);
                    if (model != null)
                    {
                        requestDetail = new CEARequest();
                        requestDetail = model;

                        // Get schedule of expenses
                        requestDetail.ScheduleExpenseList = this.GetScheduleExpenses(requisitionNo);

                        // Get file attachments
                        requestDetail.AttachmentList = this.GetFileAttachment(requisitionNo);
                    }
                }

                return requestDetail;
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

        public List<Equipment> GetEquipmentList(string equipmentNo = "", string equipmentDesc = "")
        {
            List<Equipment> equipmentList = new List<Equipment>();

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@equipmentNo", equipmentNo);
                    parameters.Add("@equipmentDesc", equipmentDesc);

                    var model = _dapperDB.Query("Projectuser.Pr_SearchEquipment", parameters, commandType: CommandType.StoredProcedure).ToList();
                    if (model.Count > 0)
                    {
                        equipmentList = new List<Equipment>();

                        foreach (var item in model)
                        {
                            equipmentList.Add(new Equipment()
                            {
                                equipmentNo = item.EquipmentNo,
                                equipmentDesc = item.EquipmentDesc,
                                parentEquipmentNo = item.ParentEquipmentNo,
                                parentEquipmentDesc = item.ParentEquipmentDesc
                            });
                        }
                    }
                }

                return equipmentList;
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

        public async Task<DBTransResult?> InsertUpdateDeleteRequisition(DataAccessType dbAccessType, CEARequest requestData)
        {
            DBTransResult? dbResult = null;
            DBTransResult? saveResult = null;
            int rowsAffected = 0;
            ADONetParameter[] parameters = new ADONetParameter[27];

            try
            {
                var appSettingOptions = new AppSettingOptions();
                _config.GetSection(AppSettingOptions.AppSettings).Bind(appSettingOptions);
                int? retError = GlobalSettings.DB_STATUS_OK;

                switch (dbAccessType)
                {
                    case DataAccessType.Create:
                        #region Insert new requisition

                        #region Initialize input parameters

                        parameters[0] = new ADONetParameter("@actionType", SqlDbType.TinyInt, Convert.ToByte(dbAccessType));
                        parameters[1] = new ADONetParameter("@requisitionID", SqlDbType.Decimal, requestData.RequisitionID);
                        parameters[2] = new ADONetParameter("@projectNo", SqlDbType.VarChar, 20, requestData.ProjectNo);
                        parameters[3] = new ADONetParameter("@requisitionDate", SqlDbType.DateTime, requestData.RequestDate!);
                        parameters[4] = new ADONetParameter("@originatorEmpNo", SqlDbType.Int, requestData.OriginatorEmpNo);
                        parameters[5] = new ADONetParameter("@plantLocation", SqlDbType.VarChar, 12, requestData.PlantLocationID!);
                        parameters[6] = new ADONetParameter("@categoryCode", SqlDbType.VarChar, 10, requestData.CategoryCode1);
                        parameters[7] = new ADONetParameter("@lifeSpan", SqlDbType.SmallInt, requestData.EstimatedLifeSpan);
                        parameters[8] = new ADONetParameter("@itemRequired", SqlDbType.VarChar, 1000, requestData.Description);
                        parameters[9] = new ADONetParameter("@reason", SqlDbType.VarChar, 1000, requestData.Reason);
                        parameters[10] = new ADONetParameter("@commissionDate", SqlDbType.DateTime, requestData.DateofComission);
                        parameters[11] = new ADONetParameter("@estimatedCost", SqlDbType.Decimal, requestData.RequestedAmt);
                        parameters[12] = new ADONetParameter("@additionalAmt", SqlDbType.Decimal, requestData.AdditionalBudgetAmtSync);
                        parameters[13] = new ADONetParameter("@requisitionDesc", SqlDbType.VarChar, 40, requestData.RequisitionDescription);
                        parameters[14] = new ADONetParameter("@reasonAdditionalAmt", SqlDbType.VarChar, 100, requestData.ReasonForAdditionalAmt);
                        parameters[15] = new ADONetParameter("@equipmentChildNo", SqlDbType.VarChar, 12, requestData.EquipmentNo!);
                        parameters[16] = new ADONetParameter("@equipmentParentNo", SqlDbType.VarChar, 12, requestData.EquipmentParentNo!);
                        parameters[17] = new ADONetParameter("@preparedBy", SqlDbType.VarChar, 50, requestData.CreatedByEmpName);
                        parameters[18] = new ADONetParameter("@preparedByEmpNo", SqlDbType.Int, requestData.CreatedByEmpNo);
                        parameters[19] = new ADONetParameter("@multipleItems", SqlDbType.Bit, requestData.MultipleItems);
                        #endregion

                        #region Save to database 
                        using (SqlConnection con = new SqlConnection(_connectionString))
                        {
                            using (SqlCommand command = new SqlCommand())
                            {
                                command.CommandType = CommandType.StoredProcedure;
                                command.CommandText = "Projectuser.Pr_Requisition_CUD";
                                command.CommandTimeout = 300;
                                command.Connection = con;

                                CompileParameters(command, parameters);

                                // Initialize output parameters                                  
                                SqlParameter paramRequisitionID = AddParameter(command, "@newRequisitionID", SqlDbType.Int, ParameterDirection.InputOutput, 0);
                                SqlParameter paramRequisitionNo = AddParameter(command, "@requisitionNo", SqlDbType.VarChar, ParameterDirection.InputOutput, string.Empty, 50);

                                // Establish DB connection
                                con.Open();
                                rowsAffected = command.ExecuteNonQuery();

                                // Fetch the value of the output parameters
                                requestData.RequisitionID = _converter.ConvertObjectToDecimal(paramRequisitionID.Value);
                                requestData.RequisitionNo = _converter.ConvertObjectToString(paramRequisitionNo.Value);
                            }

                            #region Save Schedule of Expenses
                            if (requestData.ScheduleExpenseList != null)
                            {
                                foreach (var item in requestData.ScheduleExpenseList)
                                {
                                    item.RequisitionID = _converter.ConvertObjectToInt(requestData.RequisitionNo);      // Store Requisition No. into Requisition ID field
                                }

                                InsertUpdateDeleteExpenses(DataAccessType.Create, requestData.ScheduleExpenseList);
                            }
                            #endregion

                            #region Save File Attachments
                            if (requestData.AttachmentList != null)
                            {
                                foreach (var item in requestData.AttachmentList)
                                {
                                    item.RequisitionID = requestData.RequisitionID;
                                }

                                InsertUpdateDeleteAttachment(DataAccessType.Create, requestData.AttachmentList);
                            }
                            #endregion
                            
                            if (!requestData.IsDraft)
                            {
                                #region Save CEA information to JDE
                                saveResult = this.SaveRequisitionToOneWorld(Convert.ToInt32(requestData.RequisitionID), requestData.DateofComission, requestData.RequisitionDescription, requestData.ProjectNo, requestData.CreatedByUserID!, requestData.WorkstationID!);
                                if (saveResult != null && saveResult.HasError)
                                {
                                    if (!string.IsNullOrEmpty(saveResult.ErrorDesc))
                                        throw new Exception(saveResult.ErrorDesc);
                                    else
                                        throw new Exception("Unable to save CEA information into the JDE system!");
                                }
                                #endregion

                                #region Set the requisition approvers 
                                saveResult = this.ConfigureApprovers(Convert.ToInt32(requestData.RequisitionID));
                                if (saveResult != null && saveResult.HasError)
                                {
                                    if (!string.IsNullOrEmpty(saveResult.ErrorDesc))
                                        throw new Exception(saveResult.ErrorDesc);
                                    else
                                        throw new Exception("Unable to initialize the request approvers!");
                                }
                                #endregion

                                #region Set the requisition status to "Submitted for Approval" 
                                saveResult = this.SetRequisitionStatus(Convert.ToInt32(requestData.RequisitionID));
                                if (saveResult != null && saveResult.HasError)
                                {
                                    if (!string.IsNullOrEmpty(saveResult.ErrorDesc))
                                        throw new Exception(saveResult.ErrorDesc);
                                    else
                                        throw new Exception("Unable to set the request status!");
                                }
                                #endregion

                                #region Initiate the workflow
                                // Start the workflow in another thread without awaiting for the result
                                //Task.Factory.StartNew(() => RunWorkflowProcess(requestData.RequisitionNo, requestData.CreatedByEmpNo, requestData.CreatedByEmpName, requestData.CreatedByUserID!), TaskCreationOptions.LongRunning);

                                DBTransResult? wfResult = await RunWorkflowProcess(requestData.RequisitionNo, requestData.CreatedByEmpNo, requestData.CreatedByEmpName, requestData.CreatedByUserID!);
                                if (wfResult != null && wfResult.HasError)
                                {
                                    if (!string.IsNullOrEmpty(wfResult.ErrorDesc))
                                        throw new Exception(wfResult.ErrorDesc);
                                    else
                                        throw new Exception("Unable to create the workflow instance due to an unknown error that occured in the database.");
                                }
                                #endregion
                            }

                            if (con.State == ConnectionState.Open)
                                con.Close();
                        }
                        #endregion

                        #region Set the return object
                        dbResult = new DBTransResult()
                        {
                            NewIdentityID = Convert.ToInt32(requestData.RequisitionID),
                            RowsAffected = rowsAffected,
                            HasError = false,
                            CEANo = requestData.RequisitionNo
                        };
                        #endregion

                        break;
                        #endregion

                    case DataAccessType.Update:
                        #region Update existing record

                        #region Initialize input parameters
                        parameters[0] = new ADONetParameter("@actionType", SqlDbType.TinyInt, Convert.ToByte(dbAccessType));
                        parameters[1] = new ADONetParameter("@requisitionID", SqlDbType.Decimal, requestData.RequisitionID);
                        parameters[2] = new ADONetParameter("@projectNo", SqlDbType.VarChar, 20, requestData.ProjectNo);
                        parameters[3] = new ADONetParameter("@requisitionDate", SqlDbType.DateTime, requestData.RequestDate!);
                        parameters[4] = new ADONetParameter("@originatorEmpNo", SqlDbType.Int, requestData.OriginatorEmpNo);
                        parameters[5] = new ADONetParameter("@plantLocation", SqlDbType.VarChar, 12, requestData.PlantLocationID!);
                        parameters[6] = new ADONetParameter("@categoryCode", SqlDbType.VarChar, 10, requestData.CategoryCode1);
                        parameters[7] = new ADONetParameter("@lifeSpan", SqlDbType.SmallInt, requestData.EstimatedLifeSpan);
                        parameters[8] = new ADONetParameter("@itemRequired", SqlDbType.VarChar, 1000, requestData.Description);
                        parameters[9] = new ADONetParameter("@reason", SqlDbType.VarChar, 1000, requestData.Reason);
                        parameters[10] = new ADONetParameter("@commissionDate", SqlDbType.DateTime, requestData.DateofComission);
                        parameters[11] = new ADONetParameter("@estimatedCost", SqlDbType.Decimal, requestData.RequestedAmt);
                        parameters[12] = new ADONetParameter("@additionalAmt", SqlDbType.Decimal, requestData.AdditionalBudgetAmtSync);
                        parameters[13] = new ADONetParameter("@requisitionDesc", SqlDbType.VarChar, 40, requestData.RequisitionDescription);
                        parameters[14] = new ADONetParameter("@reasonAdditionalAmt", SqlDbType.VarChar, 100, requestData.ReasonForAdditionalAmt);
                        parameters[15] = new ADONetParameter("@equipmentChildNo", SqlDbType.VarChar, 12, requestData.EquipmentNo!);
                        parameters[16] = new ADONetParameter("@equipmentParentNo", SqlDbType.VarChar, 12, requestData.EquipmentParentNo!);
                        parameters[17] = new ADONetParameter("@preparedBy", SqlDbType.VarChar, 50, requestData.CreatedByEmpName);
                        parameters[18] = new ADONetParameter("@preparedByEmpNo", SqlDbType.Int, requestData.CreatedByEmpNo);
                        parameters[19] = new ADONetParameter("@multipleItems", SqlDbType.Bit, requestData.MultipleItems);
                        #endregion

                        #region Save to database 
                        using (SqlConnection con = new SqlConnection(_connectionString))
                        {
                            using (SqlCommand command = new SqlCommand())
                            {
                                command.CommandType = CommandType.StoredProcedure;
                                command.CommandText = "Projectuser.Pr_Requisition_CUD";
                                command.CommandTimeout = 300;
                                command.Connection = con;

                                CompileParameters(command, parameters);

                                // Initialize output parameters                                  
                                SqlParameter paramRequisitionID = AddParameter(command, "@newRequisitionID", SqlDbType.Int, ParameterDirection.InputOutput, requestData.RequisitionID);
                                SqlParameter paramRequisitionNo = AddParameter(command, "@requisitionNo", SqlDbType.VarChar, ParameterDirection.InputOutput, requestData.RequisitionNo, 50);

                                // Establish DB connection
                                con.Open();
                                rowsAffected = command.ExecuteNonQuery();
                            }

                            #region Save Schedule of Expense

                            // Delete existing records
                            InsertUpdateDeleteExpenses(DataAccessType.Delete, null, _converter.ConvertObjectToInt(requestData.RequisitionNo));

                            // Insert expenses
                            if (requestData.ScheduleExpenseList != null)
                            {
                                foreach (var item in requestData.ScheduleExpenseList)
                                {
                                    item.RequisitionID = _converter.ConvertObjectToInt(requestData.RequisitionNo);      // Store Requisition No. into Requisition ID field
                                }

                                InsertUpdateDeleteExpenses(DataAccessType.Create, requestData.ScheduleExpenseList);
                            }
                            #endregion

                            #region Save File Attachments

                            // Delete existing attachments
                            InsertUpdateDeleteAttachment(DataAccessType.Delete, null, requestData.RequisitionID);

                            // Insert attachments
                            if (requestData.AttachmentList != null)
                            {
                                foreach (var item in requestData.AttachmentList)
                                {
                                    item.RequisitionID = requestData.RequisitionID;
                                }

                                InsertUpdateDeleteAttachment(DataAccessType.Create, requestData.AttachmentList);
                            }
                            #endregion

                            if (!requestData.IsDraft)
                            {
                                #region Save CEA information to JDE
                                saveResult = this.SaveRequisitionToOneWorld(Convert.ToInt32(requestData.RequisitionID), requestData.DateofComission, requestData.RequisitionDescription, requestData.ProjectNo, requestData.CreatedByUserID!, requestData.WorkstationID!);
                                if (saveResult != null && saveResult.HasError)
                                {
                                    if (!string.IsNullOrEmpty(saveResult.ErrorDesc))
                                        throw new Exception(saveResult.ErrorDesc);
                                    else
                                        throw new Exception("Unable to save CEA information into the JDE system!");
                                }
                                #endregion

                                #region Set the requisition approvers 
                                saveResult = this.ConfigureApprovers(Convert.ToInt32(requestData.RequisitionID));
                                if (saveResult != null && saveResult.HasError)
                                {
                                    if (!string.IsNullOrEmpty(saveResult.ErrorDesc))
                                        throw new Exception(saveResult.ErrorDesc);
                                    else
                                        throw new Exception("Unable to initialize the request approvers!");
                                }
                                #endregion

                                #region Set requisition status to "Submitted for Approval" 
                                saveResult = this.SetRequisitionStatus(Convert.ToInt32(requestData.RequisitionID));
                                if (saveResult != null && saveResult.HasError)
                                {
                                    if (!string.IsNullOrEmpty(saveResult.ErrorDesc))
                                        throw new Exception(saveResult.ErrorDesc);
                                    else
                                        throw new Exception("Unable to set the request status!");
                                }
                                #endregion

                                #region Initiate the workflow   
                                // Start the workflow in another thread without awaiting for the result
                                //Task.Factory.StartNew(() => RunWorkflowProcess(requestData.RequisitionNo, requestData.CreatedByEmpNo, requestData.CreatedByEmpName, requestData.CreatedByUserID!), TaskCreationOptions.LongRunning);

                                DBTransResult? wfResult = await RunWorkflowProcess(requestData.RequisitionNo, requestData.CreatedByEmpNo, requestData.CreatedByEmpName, requestData.CreatedByUserID!);
                                if (wfResult != null && wfResult.HasError)
                                {
                                    if (!string.IsNullOrEmpty(wfResult.ErrorDesc))
                                        throw new Exception(wfResult.ErrorDesc);
                                    else
                                        throw new Exception("Unable to create the workflow instance due to an unknown error that occured in the database.");
                                }
                                #endregion
                            }

                            if (con.State == ConnectionState.Open)
                                con.Close();
                        }
                        #endregion

                        #region Set the return object
                        dbResult = new DBTransResult()
                        {
                            RowsAffected = rowsAffected,
                            HasError = false
                        };
                        #endregion

                        break;
                    #endregion

                    case DataAccessType.Delete:
                        #region Delete existing record

                        #region Initialize input parameters
                        parameters[0] = new ADONetParameter("@actionType", SqlDbType.TinyInt, Convert.ToByte(dbAccessType));
                        parameters[1] = new ADONetParameter("@requisitionID", SqlDbType.Decimal, requestData.RequisitionID);
                        parameters[2] = new ADONetParameter("@projectNo", SqlDbType.VarChar, 20, requestData.ProjectNo);
                        parameters[3] = new ADONetParameter("@requisitionDate", SqlDbType.DateTime, requestData.RequestDate!);
                        parameters[4] = new ADONetParameter("@originatorEmpNo", SqlDbType.Int, requestData.OriginatorEmpNo);
                        parameters[5] = new ADONetParameter("@plantLocation", SqlDbType.VarChar, 12, requestData.PlantLocationID!);
                        parameters[6] = new ADONetParameter("@categoryCode", SqlDbType.VarChar, 10, requestData.CategoryCode1);
                        parameters[7] = new ADONetParameter("@lifeSpan", SqlDbType.SmallInt, requestData.EstimatedLifeSpan);
                        parameters[8] = new ADONetParameter("@itemRequired", SqlDbType.VarChar, 1000, requestData.Description);
                        parameters[9] = new ADONetParameter("@reason", SqlDbType.VarChar, 1000, requestData.Reason);
                        parameters[10] = new ADONetParameter("@commissionDate", SqlDbType.DateTime, requestData.DateofComission);
                        parameters[11] = new ADONetParameter("@estimatedCost", SqlDbType.Decimal, requestData.RequestedAmt);
                        parameters[12] = new ADONetParameter("@additionalAmt", SqlDbType.Decimal, requestData.AdditionalBudgetAmt);
                        parameters[13] = new ADONetParameter("@requisitionDesc", SqlDbType.VarChar, 40, requestData.RequisitionDescription);
                        parameters[14] = new ADONetParameter("@reasonAdditionalAmt", SqlDbType.VarChar, 100, requestData.ReasonForAdditionalAmt);
                        parameters[15] = new ADONetParameter("@equipmentChildNo", SqlDbType.VarChar, 12, requestData.EquipmentNo!);
                        parameters[16] = new ADONetParameter("@equipmentParentNo", SqlDbType.VarChar, 12, requestData.EquipmentParentNo!);
                        parameters[17] = new ADONetParameter("@preparedBy", SqlDbType.VarChar, 50, requestData.CreatedByEmpName);
                        parameters[18] = new ADONetParameter("@preparedByEmpNo", SqlDbType.Int, requestData.CreatedByEmpNo);
                        parameters[19] = new ADONetParameter("@multipleItems", SqlDbType.Bit, requestData.MultipleItems);
                        #endregion

                        #region Save to database 
                        using (SqlConnection con = new SqlConnection(_connectionString))
                        {
                            using (SqlCommand command = new SqlCommand())
                            {
                                command.CommandType = CommandType.StoredProcedure;
                                command.CommandText = "Projectuser.Pr_Requisition_CUD";
                                command.CommandTimeout = 300;
                                command.Connection = con;

                                CompileParameters(command, parameters);

                                // Initialize output parameters                                  
                                SqlParameter paramRequisitionID = AddParameter(command, "@newRequisitionID", SqlDbType.Int, ParameterDirection.InputOutput, requestData.RequisitionID);
                                SqlParameter paramRequisitionNo = AddParameter(command, "@requisitionNo", SqlDbType.VarChar, ParameterDirection.InputOutput, requestData.RequisitionNo, 50);

                                // Establish DB connection
                                con.Open();
                                rowsAffected = command.ExecuteNonQuery();
                            }

                            // Delete schedule of expense records
                            InsertUpdateDeleteExpenses(DataAccessType.Delete, null, _converter.ConvertObjectToInt(requestData.RequisitionNo));

                            if (con.State == ConnectionState.Open)
                                con.Close();
                        }
                        #endregion

                        #region Set the return object
                        dbResult = new DBTransResult()
                        {
                            RowsAffected = rowsAffected,
                            HasError = false
                        };
                        #endregion

                        break;
                        #endregion
                }

                return dbResult;
            }
            catch (SqlException sqlErr)
            {
                return new DBTransResult()
                {
                    HasError = true,
                    ErrorCode = sqlErr.HResult.ToString(),
                    ErrorDesc = sqlErr.Message.ToString()
                };
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

        public async Task<DBTransResult?> ChangeRequisitionStatus(string requisitionNo, string actionType, int empNo, string comments, string cancelledByName, string wfInstanceID)
        {
            DBTransResult? dbResult = null;
            int rowsAffected = 0;

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@requisitionNo", requisitionNo);
                    parameters.Add("@actionType", actionType);
                    parameters.Add("@empNo", empNo, dbType: DbType.Int32);
                    parameters.Add("@comments", comments);
                    parameters.Add("@rowsAffected", 0, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);
                    parameters.Add("@hasError", false, dbType: DbType.Boolean, direction: ParameterDirection.InputOutput);
                    parameters.Add("@retError", 0, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);
                    parameters.Add("@retErrorDesc", string.Empty, dbType: DbType.String, direction: ParameterDirection.InputOutput);

                    // Save to database
                    rowsAffected = _dapperDB.Execute("Projectuser.Pr_ChangeRequisitionStatus", parameters, commandType: CommandType.StoredProcedure);
                    
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
                                ErrorDesc = "Unable to update the requisition status due to unknown error in the backend database."
                            };
                        }
                    }
                    else
                    {

                        #region Invoke the workflow approval process
                        if (!string.IsNullOrEmpty(wfInstanceID))
                        {
                            var wfTransResult = await this.InvokeWFCancelRequest(Convert.ToInt32(requisitionNo), wfInstanceID, empNo, cancelledByName);
                            if (wfTransResult != null && wfTransResult.HasError)
                            {
                                if (!string.IsNullOrEmpty(wfTransResult.ErrorDesc))
                                    throw new Exception(wfTransResult.ErrorDesc);
                                else
                                    throw new Exception("Unable to complete the workflow approval process due to an unknown error that occured within the service.");
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

                return dbResult;
            }
            catch (SqlException sqlErr)
            {
                throw new Exception(sqlErr.Message.ToString());
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

        public async Task<List<WFApprovalStatus>> GetWorkflowStatus(string ceaNo)
        {
            try
            {
                #region Fetch data using EF Core
                string sql = "EXEC Projectuser.Pr_GetRequestWFStatus @ceaNo";

                // Create parameters
                List<SqlParameter> parms = new List<SqlParameter>
                {
                    new SqlParameter { ParameterName = "@ceaNo", SqlDbType = SqlDbType.VarChar, Size = 50, Value = ceaNo,  },
                };

                var model = await _db.WorkflowStatusDetail
                    .FromSqlRaw(sql, parms.ToArray())
                    .AsNoTracking()
                    .ToListAsync();

                return model;
                #endregion
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

        public List<WFApprovalStatus> GetWorkflowStatusOld(string ceaNo)
        {
            List<WFApprovalStatus> statusList = new List<WFApprovalStatus>();

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@ceaNo", ceaNo);

                    var model = _dapperDB.Query("Projectuser.Pr_GetRequestWFStatus", parameters, commandType: CommandType.StoredProcedure).ToList();
                    if (model.Count > 0)
                    {
                        statusList = new List<WFApprovalStatus>();

                        foreach (var item in model)
                        {
                            statusList.Add(new WFApprovalStatus()
                            {
                                activityID = item.ActivityID,
                                approvalRole = item.ApprovalRole,
                                approver = item.Approver,
                                currentStatus = item.CurrentStatus,
                                approvedDate = item.ApprovedDate,
                                approverRemarks = item.ApproverRemarks,
                                activityCode = item.ActivityCode,
                                activitySequence = item.ActivitySequence,
                                projectNo = item.ProjectNo,
                                projectType = item.ProjectType,
                                approverPosition = item.ApproverPosition
                            });
                        }
                    }
                }

                return statusList;
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

        public async Task<DBTransResult?> ReassignRequest(string requisitionNo, int currentAssignedEmpNo, int reassignedEmpNo, string reassignedEmpName, string reassignedEmpEmail, 
            int routineSeq, bool onHold, string reason, int reassignedBy, string reassignedName, string wfInstanceID, string ceaDescription)
        {
            DBTransResult? dbResult = null;
            int rowsAffected = 0;

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@requisitionNo", requisitionNo);
                    parameters.Add("@reassignedByEmpNo", reassignedBy, dbType: DbType.Int32);
                    parameters.Add("@reassignedToEmpNo", reassignedEmpNo, dbType: DbType.Int32);
                    parameters.Add("@justification", reason);
                    parameters.Add("@rowsAffected", 0, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);
                    parameters.Add("@hasError", false, dbType: DbType.Boolean, direction: ParameterDirection.InputOutput);
                    parameters.Add("@retError", 0, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);
                    parameters.Add("@retErrorDesc", string.Empty, dbType: DbType.String, direction: ParameterDirection.InputOutput);

                    // Save to database
                    rowsAffected = _dapperDB.Execute("Projectuser.Pr_ReassignToApprover", parameters, commandType: CommandType.StoredProcedure);

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
                        if (!string.IsNullOrEmpty(wfInstanceID))
                        {
                            #region Invoke the workflow reassignment if the CEA request is created using the new system
                            // Start the workflow in another thread without awaiting for the result
                            //Task.Factory.StartNew(() => InvokeWFReassignRequest(Convert.ToInt32(requisitionNo), wfInstanceID, currentAssignedEmpNo, reassignedEmpNo, reassignedEmpName,
                            //    reassignedEmpEmail, routineSeq, onHold, reason, reassignedBy, reassignedName));

                            var wfTransResult = await this.InvokeWFReassignRequest(Convert.ToInt32(requisitionNo), wfInstanceID, currentAssignedEmpNo, reassignedEmpNo, reassignedEmpName,
                                reassignedEmpEmail, routineSeq, onHold, reason, reassignedBy, reassignedName);
                            if (wfTransResult != null && wfTransResult.HasError)
                            {
                                if (!string.IsNullOrEmpty(wfTransResult.ErrorDesc))
                                    throw new Exception(wfTransResult.ErrorDesc);
                                else
                                    throw new Exception("Unable to complete the reassignment process due to an unknown error that occured within the workflow service.");
                            }
                            #endregion
                        }
                        else
                        {
                            // Notify the new approver using separate thread
                            Task.Factory.StartNew(() => SendEmailToReassignedApprover(reassignedEmpName, reassignedEmpEmail, requisitionNo, ceaDescription), TaskCreationOptions.LongRunning);
                        }

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
                return new DBTransResult()
                {
                    HasError = true,
                    ErrorCode = ex.HResult.ToString(),
                    ErrorDesc = ex.Message.ToString()
                };
            }
        }
        #endregion

        #region ADO.NET Extension Methods
        public SqlParameter AddParameter(SqlCommand command, string parameterName, SqlDbType dbType, ParameterDirection direction)
        {
            SqlParameter parameter = new SqlParameter(parameterName, dbType);
            parameter.Direction = direction;
            command.Parameters.Add(parameter);
            return parameter;
        }

        public SqlParameter AddParameter(SqlCommand command, string parameterName, SqlDbType dbType, ParameterDirection direction, object parameterValue)
        {
            SqlParameter parameter = new SqlParameter(parameterName, dbType);
            parameter.Direction = direction;
            parameter.Value = parameterValue;
            command.Parameters.Add(parameter);

            return parameter;
        }

        public SqlParameter AddParameter(SqlCommand command, string parameterName, SqlDbType dbType, ParameterDirection direction, object parameterValue, int parameterSize)
        {
            SqlParameter parameter = new SqlParameter(parameterName, dbType);
            parameter.Direction = direction;
            parameter.Size = parameterSize;

            if (parameterValue != null)
                parameter.Value = parameterValue;

            command.Parameters.Add(parameter);

            return parameter;
        }

        public DataSet RunSPReturnDataset(string spName, string connectionString, params ADONetParameter[] parameters)
        {
            try
            {
                SqlConnection connection = new SqlConnection()
                {
                    ConnectionString = connectionString
                };

                using (SqlCommand command = new SqlCommand())
                {
                    command.CommandType = CommandType.StoredProcedure;
                    command.CommandText = spName;
                    command.CommandTimeout = 300;
                    command.Connection = connection;

                    CompileParameters(command, parameters);
                    //AddSQLCommand(command);

                    using (SqlDataAdapter adapter = new SqlDataAdapter())
                    {
                        adapter.SelectCommand = command;
                        adapter.SelectCommand.CommandTimeout = 300;
                        DataSet ds = new DataSet();
                        adapter.Fill(ds);
                        return ds;
                    }
                }
            }
            catch (Exception ex)
            {
                throw new ApplicationException(ex.Message, ex);
            }
        }

        public void CompileParameters(SqlCommand comm, ADONetParameter[] parameters)
        {
            try
            {
                foreach (ADONetParameter parameter in parameters)
                {
                    if (parameter == null)
                        continue;

                    if (parameter.ParameterValue == null)
                        parameter.ParameterValue = DBNull.Value;

                    comm.Parameters.Add(parameter.Parameter);
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        #endregion

        #region Workflow Methods
        public async Task<DBTransResult?> RunWorkflowProcess(string ceaNo, int userEmpNo, string userEmpName, string userID)
        {
            DBTransResult? saveResult = null;
            int? retError = 0;

            try
            {
                // Insert CEA workflow record
                saveResult = this.CreateWFTransaction(Convert.ToByte(GlobalSettings.WFActionType.SubmitRequest), ceaNo, GlobalSettings.STATUS_CODE_REQUEST_SENT, false, userEmpNo, userEmpName, userID);
                if (saveResult != null)
                {
                    if (saveResult.HasError)
                    {
                        if (!string.IsNullOrEmpty(saveResult.ErrorDesc))
                            throw new Exception(saveResult.ErrorDesc);
                        else
                            throw new Exception("Unable to create the workflow transaction record due to an unknown error that occured in the database.");
                    }
                    else
                    {
                        #region Creates transactional workflow data
                        TransProcessWFBLL wfBLL = new TransProcessWFBLL(_gapConnectionString);
                        wfBLL.CreateTransactionProcessWF(GlobalSettings.REQUEST_TYPE_CEA, Convert.ToInt32(ceaNo), userEmpNo, ref retError);
                        #endregion
                    }
                }

                #region Start the workflow process
                if (retError == GlobalSettings.DB_STATUS_OK)
                {
                    string wfInstanceID = await InvokeWorkflowProcess(Convert.ToInt32(ceaNo), userEmpNo, userEmpName);

                    if (!string.IsNullOrWhiteSpace(wfInstanceID))
                    {
                        saveResult = UpdateServiceRequestInstanceID(GlobalSettings.REQUEST_TYPE_CEA, Convert.ToInt32(ceaNo), wfInstanceID);
                        if (saveResult != null && saveResult.HasError)
                        {
                            if (!string.IsNullOrEmpty(saveResult.ErrorDesc))
                                throw new Exception(saveResult.ErrorDesc);
                            else
                                throw new Exception("Could not update the workflow instance id due to unknown error.");
                        }
                    }
                }
                #endregion

                return saveResult;

            }
            catch (SqlException sqlErr)
            {
                throw new Exception(sqlErr.Message.ToString());
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

        private DBTransResult? CreateWFTransaction(byte actionType, string requisitionNo, string statusCode, bool isDraft, int userEmpNo, string? userEmpName,
           string? userID, string approverRemarks = "", int reassignEmpNo = 0)
        {
            DBTransResult? dbResult = null;
            int rowsAffected = 0;

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@actionType", actionType);
                    parameters.Add("@requisitionNo", requisitionNo);
                    parameters.Add("@statusCode", statusCode);
                    parameters.Add("@isDraft", isDraft);
                    parameters.Add("@userEmpNo", userEmpNo, dbType: DbType.Int32);
                    parameters.Add("@userEmpName", userEmpName);
                    parameters.Add("@userID", userID);
                    parameters.Add("@rowsAffected", 0, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);
                    parameters.Add("@hasError", false, dbType: DbType.Boolean, direction: ParameterDirection.InputOutput);
                    parameters.Add("@retError", 0, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);
                    parameters.Add("@retErrorDesc", string.Empty, dbType: DbType.String, direction: ParameterDirection.InputOutput);
                    parameters.Add("@approverRemarks", approverRemarks);
                    parameters.Add("@reassignEmpNo", reassignEmpNo, dbType: DbType.Int32);

                    // Save to database
                    rowsAffected = _dapperDB.Execute("Projectuser.Pr_ManageCEAWorkflow", parameters, commandType: CommandType.StoredProcedure);

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
                                ErrorDesc = "Unable to create the workflow transaction record due to an unknown error that occured in the database."
                            };
                        }
                    }
                    else
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
                return new DBTransResult()
                {
                    HasError = true,
                    ErrorCode = ex.HResult.ToString(),
                    ErrorDesc = ex.Message.ToString()
                };
            }
        }

        private async Task<string> InvokeWorkflowProcess(int requisitionNo, int userEmpNo, string userEmpName)
        {
            string wfInstanceID = "";

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
                    newWFItem.MailServer = appSettingOptions.GARMCOSMTP;
                    newWFItem.ActivityStatus = Convert.ToInt32(GlobalSettings.ACTIVITY_STATUS_IN_PROGRESS);
                    newWFItem.ReturnError = Convert.ToInt32(GlobalSettings.DB_STATUS_OK);
                    newWFItem.FromEmail = appSettingOptions.AdminEmail;
                    newWFItem.FromName = appSettingOptions.AdminName;
                    newWFItem.ModifiedBy = userEmpNo;
                    newWFItem.ModifiedName = userEmpName;
                    newWFItem.IsThrowEmailException = _converter.ConvertNumberToBolean(appSettingOptions.IsThrowEmailException);   // (Note: Set to true to throw email error to the UI. Otherwise, set to false if need to ignore the error.)                
                    newWFItem.EmailTestMode = _converter.ConvertNumberToBolean(appSettingOptions.EmailTestMode);                   // (Note: Set value to true to append underscore to all To and CC email recipients but not to Bcc.)
                    newWFItem.WorkflowBccRecipients = appSettingOptions.WorkflowBccRecipients;

                    try
                    {
                        newWFItem.InstanceID = await this.WorkflowServiceProxy.InitiateRequestWorkflowAsync(newWFItem);
                    }
                    catch (FaultException<ErrorDetail> Fex)
                    {
                        throw new Exception(Fex.Detail.ErrorDescription);
                    }

                    if (!string.IsNullOrEmpty(newWFItem.InstanceID))
                    {
                        // Success
                        wfInstanceID = newWFItem.InstanceID;
                    }
                }

                return wfInstanceID;
            }
            catch (Exception ex)
            {
                throw;
            }
        }
                
        private DBTransResult? UpdateServiceRequestInstanceID(int reqType, int reqTypeNo, string reqTypenstanceID)
        {
            DBTransResult? dbResult = null;
            int rowsAffected = 0;

            try
            {
                using (_dapperDB = new SqlConnection(_gapConnectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@reqType", reqType, dbType: DbType.Int32);
                    parameters.Add("@reqTypeNo", reqTypeNo, dbType: DbType.Int32);
                    parameters.Add("@reqTypenstanceID", reqTypenstanceID);
                    parameters.Add("@retError", 0, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);

                    // Save to database
                    rowsAffected = _dapperDB.Execute("secuser.pr_UpdateServiceRequestInstanceID", parameters, commandType: CommandType.StoredProcedure);

                    // Check for errors
                    int retError = parameters.Get<int>("@retError");
                    if (retError != GlobalSettings.DB_STATUS_OK)
                    {
                        dbResult = new DBTransResult()
                        {
                            HasError = true,
                            ErrorDesc = "Unable to update the workflow instance id."
                        };
                    }
                    else
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

        public async Task<DBTransResult?> ApproveRejectRequest(string requisitionNo, string wfInstanceID, int appRole, int appRoutineSeq, bool appApproved, string appRemarks, 
            int approvedBy, string approvedName, string statusCode)
        {
            DBTransResult? dbResult = null;
            int rowsAffected = 0;
            string approversEmail = String.Empty;

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@requisitionNo", requisitionNo);
                    parameters.Add("@empNo", approvedBy, dbType: DbType.Int32);
                    parameters.Add("@statusCode", statusCode);
                    parameters.Add("@approvalComments", appRemarks);
                    parameters.Add("@nextSequence", 0, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);
                    parameters.Add("@retError", 0, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);
                    parameters.Add("@approverEmail", string.Empty, dbType: DbType.String, direction: ParameterDirection.InputOutput, 1000);

                    // Save to database
                    rowsAffected = _dapperDB.Execute("Projectuser.Pr_ApproveRequisition", parameters, commandType: CommandType.StoredProcedure);

                    // Get the next sequence no.
                    int nextSequence = parameters.Get<int>("@nextSequence");

                    if (!appApproved)
                    {
                        // Get the email address of all approvers who have approved already for sending CC copy to the rejection email
                        approversEmail = parameters.Get<string>("@approverEmail");
                    }

                    // Check for errors
                    int retError = parameters.Get<int>("@retError");
                    if (retError != GlobalSettings.DB_STATUS_OK)
                    {
                        dbResult = new DBTransResult()
                        {
                            HasError = true,
                            ErrorDesc = "Unable to complete the approval process due to an unknown error that occured while updating the database record."
                        };
                    }
                    else
                    {
                        #region Update the approver list
                        dbResult = this.UpdateApproverList(requisitionNo, nextSequence, GlobalSettings.SUBMITTED_FOR_APPROVAL);
                        if (dbResult != null && dbResult.HasError)
                        {
                            if (!string.IsNullOrEmpty(dbResult.ErrorDesc))
                                throw new Exception(dbResult.ErrorDesc);
                            else
                                throw new Exception("Unable to update the approver list due to an unknown error that occured in the database.");
                        }
                        #endregion

                        if (!string.IsNullOrEmpty(wfInstanceID))
                        {
                            #region Invoke the workflow approval process
                            var wfTransResult = await this.InvokeWFApproveRejectRequest(Convert.ToInt32(requisitionNo), wfInstanceID, appRole, appRoutineSeq, appApproved, appRemarks, approvedBy, approvedName, approversEmail);
                            if (wfTransResult != null && wfTransResult.HasError)
                            {
                                if (!string.IsNullOrEmpty(wfTransResult.ErrorDesc))
                                    throw new Exception(wfTransResult.ErrorDesc);
                                else
                                    throw new Exception("Unable to complete the workflow approval process due to an unknown error that occured within the service.");
                            }
                            #endregion

                            #region Update the workflow status to "05 - Waiting for Approval"
                            // Start the workflow in another thread without awaiting for the result
                            Task.Factory.StartNew(() => UpdateWorkflowStatus(requisitionNo, GlobalSettings.STATUS_CODE_WAITING_FOR_APPROVAL), TaskCreationOptions.LongRunning);

                            //var statusResult = this.UpdateWorkflowStatus(requisitionNo, GlobalSettings.STATUS_CODE_WAITING_FOR_APPROVAL);
                            //if (statusResult != null && statusResult.HasError)
                            //{
                            //    if (!string.IsNullOrEmpty(statusResult.ErrorDesc))
                            //        throw new Exception(statusResult.ErrorDesc);
                            //    else
                            //        throw new Exception("Unable to update the workflow status due to an unknown error that occured in the database.");
                            //}
                            #endregion
                        }
                        else
                        {
                            if (nextSequence > 0)
                            {
                                // Send email notification using separate thread
                                Task.Factory.StartNew(() => NotifyRequisitionApprovers(requisitionNo, nextSequence, GlobalSettings.SUBMITTED_FOR_APPROVAL), TaskCreationOptions.LongRunning);

                                //bool isEmailSuccess = await NotifyRequisitionApprovers(requisitionNo, nextSequence, GlobalSettings.SUBMITTED_FOR_APPROVAL);
                            }
                            else if (nextSequence == -2)
                            {
                                #region Approval process is completed
                                // Notify CEA Administrators for administrative tasks like uploading the requisition to JDE
                                Task.Factory.StartNew(() => NotifyCEAAdministrators(requisitionNo), TaskCreationOptions.LongRunning);

                                // Notify Cost Center approvers
                                Task.Factory.StartNew(() => NotifyCostCenterApprovers(requisitionNo), TaskCreationOptions.LongRunning);

                                // Notify Equipment Number admins
                                Task.Factory.StartNew(() => NotifyEquipmentAdmin(requisitionNo), TaskCreationOptions.LongRunning);
                                #endregion
                            }
                        }

                        #region Set the return object
                        dbResult = new DBTransResult()
                        {
                            RowsAffected = rowsAffected,
                            NextSequenceNo = nextSequence,
                            HasError = false
                        };
                        #endregion
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
                return new DBTransResult()
                {
                    HasError = true,
                    ErrorCode = ex.HResult.ToString(),
                    ErrorDesc = ex.Message.ToString()
                };
            }
        }

        public async Task<bool> NotifyRequisitionApprovers(string requisitionNo, int groupRountingSequence, string statusCode)
        {
            bool isSuccess = false;

            try
            {
                List<ApproversDetails> approverList = await _db.ApproversDetailList
                    .FromSqlInterpolated($"EXEC Projectuser.Pr_GetApproverList {requisitionNo}, {groupRountingSequence}, {statusCode}")
                    .AsNoTracking()
                    .ToListAsync();

                if (approverList != null && approverList.Count > 0)
                {
                    foreach (ApproversDetails item in approverList)
                    {
                        SendEmailToApprover(item.ApproverName, item.ApproverEmail, item.RequisitionNo, item.CEADescription);
                    }
                }

                return isSuccess;
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

        private DBTransResult? UpdateApproverList(string requisitionNo, int sequenceNo, string statusCode)
        {
            DBTransResult? dbResult = null;
            int rowsAffected = 0;

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@requisitionNo", requisitionNo);
                    parameters.Add("@sequenceNo", sequenceNo, dbType: DbType.Int32);
                    parameters.Add("@statusCode", statusCode);
                    parameters.Add("@retError", 0, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);

                    // Save to database
                    rowsAffected = _dapperDB.Execute("Projectuser.Pr_UpdateApproverList", parameters, commandType: CommandType.StoredProcedure);

                    // Check for errors
                    int retError = parameters.Get<int>("@retError");
                    if (retError != GlobalSettings.DB_STATUS_OK)
                    {
                        dbResult = new DBTransResult()
                        {
                            HasError = true,
                            ErrorDesc = "Unable to update the approver list due to an unknown error that occured in the database."
                        };
                    }
                    else
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
                return new DBTransResult()
                {
                    HasError = true,
                    ErrorCode = ex.HResult.ToString(),
                    ErrorDesc = ex.Message.ToString()
                };
            }
        }

        private async Task<DBTransResult?> InvokeWFApproveRejectRequest(int requisitionNo, string wfInstanceID, int appRole, int appRoutineSeq, bool appApproved, string appRemarks, int approvedBy, string approvedName, string approversEmail)
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
                    newWFItem.UserActionType = appApproved ? GARMCO.AMS.CommonWF.BL.Enumeration.UserActionType.ApproveRequest : GARMCO.AMS.CommonWF.BL.Enumeration.UserActionType.RejectRequest;

                    if (!string.IsNullOrEmpty(wfInstanceID))
                        newWFItem.WorkflowID = new Guid(wfInstanceID);

                    newWFItem.ModifiedBy = approvedBy;
                    newWFItem.ModifiedName = approvedName;
                    newWFItem.RequestApproved = appApproved;
                    newWFItem.RequestApprovedRemarks = appRemarks;
                    newWFItem.RequestRoutineSeq = appRoutineSeq;

                    if (!string.IsNullOrEmpty(approversEmail))
                        newWFItem.NotifyEmailCcRecipients = approversEmail;

                    #region Approves or Rejects
                    try
                    {
                        if (appApproved)
                            retError = await this.WorkflowServiceProxy.RequestApprovedAsync(newWFItem);
                        else
                            retError = await this.WorkflowServiceProxy.RequestRejectedAsync(newWFItem);
                    }
                    catch (FaultException<ErrorDetail> Fex)
                    {
                        throw new Exception(Fex.Detail.ErrorDescription);
                    }
                    #endregion

                    // Checks for error
                    if (retError != GlobalSettings.DB_STATUS_OK)
                    {
                        // Checks if the current assigned person is no longer in the current distribution list
                        if (!this.CheckAssignedDistributionMember(GlobalSettings.REQUEST_TYPE_CEA, requisitionNo, approvedBy, appRole, appRoutineSeq))
                            retError = GlobalSettings.DB_STATUS_OK;
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

        private DBTransResult? UpdateWorkflowStatus(string ceaNo, string statusCode)
        {
            DBTransResult? dbResult = null;
            int rowsAffected = 0;

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@ceaNo", ceaNo);
                    parameters.Add("@statusCode", statusCode);
                    parameters.Add("@rowsAffected", 0, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);
                    parameters.Add("@hasError", false, dbType: DbType.Boolean, direction: ParameterDirection.InputOutput);
                    parameters.Add("@retError", 0, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);
                    parameters.Add("@retErrorDesc", string.Empty, dbType: DbType.String, direction: ParameterDirection.InputOutput);

                    // Save to database
                    rowsAffected = _dapperDB.Execute("Projectuser.Pr_UpdateCEAStatus", parameters, commandType: CommandType.StoredProcedure);

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
                                ErrorDesc = "Unable to update the workflow status due to an unknown error that occured in the database."
                            };
                        }
                    }
                    else
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
                return new DBTransResult()
                {
                    HasError = true,
                    ErrorCode = ex.HResult.ToString(),
                    ErrorDesc = ex.Message.ToString()
                };
            }
        }

        private async Task<DBTransResult?> InvokeWFCancelRequest(int requisitionNo, string wfInstanceID, int cancelledBy, string cancelledName)
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
                    newWFItem.UserActionType = GARMCO.AMS.CommonWF.BL.Enumeration.UserActionType.CancelRequest;
                    newWFItem.ModifiedBy = cancelledBy;
                    newWFItem.ModifiedName = cancelledName;

                    if (!string.IsNullOrEmpty(wfInstanceID))
                        newWFItem.WorkflowID = new Guid(wfInstanceID);

                    #region Approves or Rejects
                    try
                    {
                        retError = await this.WorkflowServiceProxy.UserRequestCancelledAsync(newWFItem);
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
                        // Cancel the request directly
                        DBTransResult? cancelResult = this.CancelServiceRequest(GlobalSettings.REQUEST_TYPE_CEA, requisitionNo, Convert.ToUInt32(GlobalSettings.RequestTypeStatusCode.CancelledByUser).ToString(), cancelledBy, cancelledName);
                        if (cancelResult != null && cancelResult.HasError)
                        {
                            if (!string.IsNullOrEmpty(cancelResult.ErrorDesc))
                                throw new Exception(cancelResult.ErrorDesc);
                            else
                                throw new Exception($"Unable to cancel the workflow of CEA Requisition No. {requisitionNo}");
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

        private DBTransResult? CancelServiceRequest(int reqType, int reqTypeNo, string reqStatusCode, int reqModifiedBy, string reqModifiedName)
        {
            DBTransResult? dbResult = null;
            int rowsAffected = 0;

            try
            {
                using (_dapperDB = new SqlConnection(_gapConnectionString))
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@reqType", reqType, dbType: DbType.Int32);
                    parameters.Add("@reqTypeNo", reqTypeNo, dbType: DbType.Int32);
                    parameters.Add("@reqStatusCode", reqStatusCode);
                    parameters.Add("@reqModifiedBy", reqModifiedBy, dbType: DbType.Int32);
                    parameters.Add("@reqModifiedName", reqModifiedName);
                    parameters.Add("@retError", 0, dbType: DbType.Int32, direction: ParameterDirection.InputOutput);

                    // Save to database
                    rowsAffected = _dapperDB.Execute("secuser.pr_CancelServiceRequest", parameters, commandType: CommandType.StoredProcedure);

                    // Check for errors
                    int retError = parameters.Get<int>("@retError");
                    if (retError != GlobalSettings.DB_STATUS_OK)
                    {
                        dbResult = new DBTransResult()
                        {
                            HasError = true,
                            ErrorDesc = $"Unable to cancel the workflow of CEA Requisition No. {reqTypeNo}"
                        };
                    }
                    else
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
                return new DBTransResult()
                {
                    HasError = true,
                    ErrorCode = ex.HResult.ToString(),
                    ErrorDesc = ex.Message.ToString()
                };
            }
        }

        private bool NotifyCEAAdministrators(string requisitionNo)
        {
            bool isSuccess = false;

            try
            {
                List<CEAAdminInfo> adminList = GetCEAAdministrators(requisitionNo);
                if (adminList != null)
                {
                    foreach (CEAAdminInfo item in adminList)
                    {
                        SendEmailToAdministrators(item.EmpName, item.Email, requisitionNo, item.CEADescription);
                    }
                }

                return isSuccess;
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

        private bool NotifyCostCenterApprovers(string requisitionNo)
        {
            bool isSuccess = false;

            try
            {
                List<CEAAdminInfo> approverList = GetCostCenterApprovers(requisitionNo);
                if (approverList != null)
                {
                    foreach (CEAAdminInfo item in approverList)
                    {
                        SendEmailToCostCenterApprover(item.EmpName, item.Email, requisitionNo, item.CEADescription);
                    }
                }

                return isSuccess;
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

        private bool NotifyEquipmentAdmin(string requisitionNo)
        {
            bool isSuccess = false;

            try
            {
                List<CEAAdminInfo> approverList = GetEquipmentAdmin(requisitionNo);
                if (approverList != null)
                {
                    foreach (CEAAdminInfo item in approverList)
                    {
                        SendEmailToEquipmentAdmin(item.EmpName, item.Email, requisitionNo, item.CEADescription);
                    }
                }

                return isSuccess;
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
        #endregion

        #region Email Communication
        private bool SendEmailToApprover(string? approverName, string? approverEmail, string? ceaNo, string? ceaDescription)
        {
            bool isSuccess = false;

            try
            {
                var appSettingOptions = new AppSettingOptions();
                _config.GetSection(AppSettingOptions.AppSettings).Bind(appSettingOptions);

                #region Perform Validation
                //Check mail server
                string mailServer = appSettingOptions.GARMCOSMTP;
                if (string.IsNullOrEmpty(mailServer))
                    return false;
                #endregion

                #region Initialize variables
                int retError = 0;
                string errorMsg = string.Empty;
                string error = string.Empty;
                string innerError = string.Empty;
                #endregion

                #region Set the From, Subject, and primary recipients
                string adminAlias = appSettingOptions.AdminName;
                MailAddress from = new MailAddress(appSettingOptions.AdminEmail, !string.IsNullOrEmpty(adminAlias) ? adminAlias : "CEA System Administrator");
                string subject = $"CEA/MRE Requisition #{ceaNo} - {ceaDescription}";
                #endregion

                #region Set the Mail Recipients
                List<MailAddress> toList = null;
                List<MailAddress> ccList = null;
                List<MailAddress> bccList = null;

                #region Set the To recipients
                // Initialize the collection
                toList = new List<MailAddress>();

                if (!string.IsNullOrEmpty(approverEmail) &&
                    !string.IsNullOrEmpty(approverName))
                {
                    toList.Add(new MailAddress(approverEmail, _converter.ConvertStringToTitleCase(approverName)));
                }
                #endregion

                #region Set the Bcc recipients (For tracking purpose)
                if (!string.IsNullOrEmpty(appSettingOptions.WorkflowBccRecipients))
                {
                    string[] recipients = appSettingOptions.WorkflowBccRecipients.Split(';');
                    if (recipients != null && recipients.Count() > 0)
                    {
                        bccList = new List<MailAddress>();
                        foreach (string recipient in recipients)
                        {
                            if (recipient.Length > 0)
                                bccList.Add(new MailAddress(recipient, recipient));
                        }
                    }
                }
                #endregion

                #endregion

                // Exit if Mail-to recipient is null
                if (toList == null || toList.Count == 0)
                    return false;

                #region Set Message Body
                string body = String.Empty;
                string url = string.Format(@"{0}UserFunctions/Project/CEARequisition?requisitionNo={1}&actionType=3", appSettingOptions.SiteUrl, ceaNo);
                string adminName = appSettingOptions.AdminName; 

                // Set the path of the xml message and the url
                string appPath = Environment.CurrentDirectory;
                if (Environment.CurrentDirectory.IndexOf("\\bin") > -1)
                    appPath = Environment.CurrentDirectory.Substring(0, Environment.CurrentDirectory.IndexOf("\\bin"));

                using (StreamReader reader = new StreamReader(appPath + @"\wwwroot\MailTemplates\NotifyApprover.html"))
                {
                    body = reader.ReadToEnd();
                }

                // Build the message body
                if (!string.IsNullOrEmpty(body))
                {
                    body = body.Replace("@1", _converter.ConvertStringToTitleCase(approverName!));
                    body = body.Replace("@2", ceaNo);
                    body = body.Replace("@3", url);
                    body = body.Replace("@4", ceaNo);
                }
                #endregion

                #region Create attachment
                List<Attachment> attachmentList = null;
                #endregion

                #region Send the e-mail
                if (!string.IsNullOrEmpty(body))
                {
                    retError = 0;
                    errorMsg = string.Empty;
                    SendEmail(toList, ccList, bccList, from, subject, body, attachmentList, mailServer, ref errorMsg, ref retError);
                    if (!string.IsNullOrEmpty(errorMsg))
                    {
                        throw new Exception(errorMsg);
                    }
                }
                #endregion

                return isSuccess;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        private bool SendEmailToAdministrators(string? approverName, string? approverEmail, string? ceaNo, string? ceaDescription)
        {
            bool isSuccess = false;

            try
            {
                var appSettingOptions = new AppSettingOptions();
                _config.GetSection(AppSettingOptions.AppSettings).Bind(appSettingOptions);

                #region Perform Validation
                //Check mail server
                string mailServer = appSettingOptions.GARMCOSMTP;
                if (string.IsNullOrEmpty(mailServer))
                    return false;
                #endregion

                #region Initialize variables
                int retError = 0;
                string errorMsg = string.Empty;
                string error = string.Empty;
                string innerError = string.Empty;
                #endregion

                #region Set the From, Subject, and primary recipients
                string adminAlias = appSettingOptions.AdminName;
                MailAddress from = new MailAddress(appSettingOptions.AdminEmail, !string.IsNullOrEmpty(adminAlias) ? adminAlias : "CEA System Administrator");
                string subject = $"CEA/MRE Requisition #{ceaNo} - {ceaDescription}";
                #endregion

                #region Set the Mail Recipients
                List<MailAddress> toList = null;
                List<MailAddress> ccList = null;
                List<MailAddress> bccList = null;

                #region Set the To recipients
                // Initialize the collection
                toList = new List<MailAddress>();

                if (!string.IsNullOrEmpty(approverEmail) &&
                    !string.IsNullOrEmpty(approverName))
                {
                    toList.Add(new MailAddress(approverEmail, _converter.ConvertStringToTitleCase(approverName)));
                }
                #endregion

                #region Set the Bcc recipients (For tracking purpose)
                if (!string.IsNullOrEmpty(appSettingOptions.WorkflowBccRecipients))
                {
                    string[] recipients = appSettingOptions.WorkflowBccRecipients.Split(';');
                    if (recipients != null && recipients.Count() > 0)
                    {
                        bccList = new List<MailAddress>();
                        foreach (string recipient in recipients)
                        {
                            if (recipient.Length > 0)
                                bccList.Add(new MailAddress(recipient, recipient));
                        }
                    }
                }
                #endregion

                #endregion

                // Exit if Mail-to recipient is null
                if (toList == null || toList.Count == 0)
                    return false;

                #region Set Message Body
                string body = String.Empty;
                string url = string.Format(@"{0}AdminFunctions/Admin/RequisitionAdmin", appSettingOptions.SiteUrl);
                string adminName = appSettingOptions.AdminName;

                // Set the path of the xml message and the url
                string appPath = Environment.CurrentDirectory;
                if (Environment.CurrentDirectory.IndexOf("\\bin") > -1)
                    appPath = Environment.CurrentDirectory.Substring(0, Environment.CurrentDirectory.IndexOf("\\bin"));

                using (StreamReader reader = new StreamReader(appPath + @"\wwwroot\MailTemplates\NotifyAdministrators.html"))
                {
                    body = reader.ReadToEnd();
                }

                // Build the message body
                if (!string.IsNullOrEmpty(body))
                {
                    body = body.Replace("@1", _converter.ConvertStringToTitleCase(approverName!));
                    body = body.Replace("@2", ceaNo);
                    body = body.Replace("@3", url);
                    body = body.Replace("@4", ceaNo);
                }
                #endregion

                #region Create attachment
                List<Attachment> attachmentList = null;
                #endregion

                #region Send the e-mail
                if (!string.IsNullOrEmpty(body))
                {
                    retError = 0;
                    errorMsg = string.Empty;
                    SendEmail(toList, ccList, bccList, from, subject, body, attachmentList, mailServer, ref errorMsg, ref retError);
                    if (!string.IsNullOrEmpty(errorMsg))
                    {
                        throw new Exception(errorMsg);
                    }
                }
                #endregion

                return isSuccess;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        private bool SendEmailToCostCenterApprover(string? approverName, string? approverEmail, string? ceaNo, string? ceaDescription)
        {
            bool isSuccess = false;

            try
            {
                var appSettingOptions = new AppSettingOptions();
                _config.GetSection(AppSettingOptions.AppSettings).Bind(appSettingOptions);

                #region Perform Validation
                //Check mail server
                string mailServer = appSettingOptions.GARMCOSMTP;
                if (string.IsNullOrEmpty(mailServer))
                    return false;
                #endregion

                #region Initialize variables
                int retError = 0;
                string errorMsg = string.Empty;
                string error = string.Empty;
                string innerError = string.Empty;
                #endregion

                #region Set the From, Subject, and primary recipients
                string adminAlias = appSettingOptions.AdminName;
                MailAddress from = new MailAddress(appSettingOptions.AdminEmail, !string.IsNullOrEmpty(adminAlias) ? adminAlias : "CEA System Administrator");
                string subject = $"CEA/MRE Requisition #{ceaNo} - {ceaDescription}";
                #endregion

                #region Set the Mail Recipients
                List<MailAddress> toList = null;
                List<MailAddress> ccList = null;
                List<MailAddress> bccList = null;

                #region Set the To recipients
                // Initialize the collection
                toList = new List<MailAddress>();

                if (!string.IsNullOrEmpty(approverEmail) &&
                    !string.IsNullOrEmpty(approverName))
                {
                    toList.Add(new MailAddress(approverEmail, _converter.ConvertStringToTitleCase(approverName)));
                }
                #endregion

                #region Set the Bcc recipients (For tracking purpose)
                if (!string.IsNullOrEmpty(appSettingOptions.WorkflowBccRecipients))
                {
                    string[] recipients = appSettingOptions.WorkflowBccRecipients.Split(';');
                    if (recipients != null && recipients.Count() > 0)
                    {
                        bccList = new List<MailAddress>();
                        foreach (string recipient in recipients)
                        {
                            if (recipient.Length > 0)
                                bccList.Add(new MailAddress(recipient, recipient));
                        }
                    }
                }
                #endregion

                #endregion

                // Exit if Mail-to recipient is null
                if (toList == null || toList.Count == 0)
                    return false;

                #region Set Message Body
                string body = String.Empty;
                string url = string.Format(@"{0}UserFunctions/Project/CEARequisition?requisitionNo={1}&actionType=0", appSettingOptions.SiteUrl, ceaNo);
                string adminName = appSettingOptions.AdminName;

                // Set the path of the xml message and the url
                string appPath = Environment.CurrentDirectory;
                if (Environment.CurrentDirectory.IndexOf("\\bin") > -1)
                    appPath = Environment.CurrentDirectory.Substring(0, Environment.CurrentDirectory.IndexOf("\\bin"));

                using (StreamReader reader = new StreamReader(appPath + @"\wwwroot\MailTemplates\NotifyCostCenter.html"))
                {
                    body = reader.ReadToEnd();
                }

                // Build the message body
                if (!string.IsNullOrEmpty(body))
                {
                    body = body.Replace("@1", _converter.ConvertStringToTitleCase(approverName!));
                    body = body.Replace("@2", ceaNo);
                    body = body.Replace("@3", url);
                    body = body.Replace("@4", ceaNo);
                }
                #endregion

                #region Create attachment
                List<Attachment> attachmentList = null;
                #endregion

                #region Send the e-mail
                if (!string.IsNullOrEmpty(body))
                {
                    retError = 0;
                    errorMsg = string.Empty;
                    SendEmail(toList, ccList, bccList, from, subject, body, attachmentList, mailServer, ref errorMsg, ref retError);
                    if (!string.IsNullOrEmpty(errorMsg))
                    {
                        throw new Exception(errorMsg);
                    }
                }
                #endregion

                return isSuccess;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        private bool SendEmailToEquipmentAdmin(string? approverName, string? approverEmail, string? ceaNo, string? ceaDescription)
        {
            bool isSuccess = false;

            try
            {
                var appSettingOptions = new AppSettingOptions();
                _config.GetSection(AppSettingOptions.AppSettings).Bind(appSettingOptions);

                #region Perform Validation
                //Check mail server
                string mailServer = appSettingOptions.GARMCOSMTP;
                if (string.IsNullOrEmpty(mailServer))
                    return false;
                #endregion

                #region Initialize variables
                int retError = 0;
                string errorMsg = string.Empty;
                string error = string.Empty;
                string innerError = string.Empty;
                #endregion

                #region Set the From, Subject, and primary recipients
                string adminAlias = appSettingOptions.AdminName;
                MailAddress from = new MailAddress(appSettingOptions.AdminEmail, !string.IsNullOrEmpty(adminAlias) ? adminAlias : "CEA System Administrator");
                string subject = $"CEA/MRE Requisition #{ceaNo} - {ceaDescription}";
                #endregion

                #region Set the Mail Recipients
                List<MailAddress> toList = null;
                List<MailAddress> ccList = null;
                List<MailAddress> bccList = null;

                #region Set the To recipients
                // Initialize the collection
                toList = new List<MailAddress>();

                if (!string.IsNullOrEmpty(approverEmail) &&
                    !string.IsNullOrEmpty(approverName))
                {
                    toList.Add(new MailAddress(approverEmail, _converter.ConvertStringToTitleCase(approverName)));
                }
                #endregion

                #region Set the Bcc recipients (For tracking purpose)
                if (!string.IsNullOrEmpty(appSettingOptions.WorkflowBccRecipients))
                {
                    string[] recipients = appSettingOptions.WorkflowBccRecipients.Split(';');
                    if (recipients != null && recipients.Count() > 0)
                    {
                        bccList = new List<MailAddress>();
                        foreach (string recipient in recipients)
                        {
                            if (recipient.Length > 0)
                                bccList.Add(new MailAddress(recipient, recipient));
                        }
                    }
                }
                #endregion

                #endregion

                // Exit if Mail-to recipient is null
                if (toList == null || toList.Count == 0)
                    return false;

                #region Set Message Body
                string body = String.Empty;
                string url = string.Format(@"{0}AdminFunctions/Admin/ManageEquipmentNo", appSettingOptions.SiteUrl);
                string adminName = appSettingOptions.AdminName;

                // Set the path of the xml message and the url
                string appPath = Environment.CurrentDirectory;
                if (Environment.CurrentDirectory.IndexOf("\\bin") > -1)
                    appPath = Environment.CurrentDirectory.Substring(0, Environment.CurrentDirectory.IndexOf("\\bin"));

                using (StreamReader reader = new StreamReader(appPath + @"\wwwroot\MailTemplates\NotifyEquipmentAdmin.html"))
                {
                    body = reader.ReadToEnd();
                }

                // Build the message body
                if (!string.IsNullOrEmpty(body))
                {
                    body = body.Replace("@1", _converter.ConvertStringToTitleCase(approverName!));
                    body = body.Replace("@2", ceaNo);
                    body = body.Replace("@3", url);
                    body = body.Replace("@4", ceaNo);
                }
                #endregion

                #region Create attachment
                List<Attachment> attachmentList = null;
                #endregion

                #region Send the e-mail
                if (!string.IsNullOrEmpty(body))
                {
                    retError = 0;
                    errorMsg = string.Empty;
                    SendEmail(toList, ccList, bccList, from, subject, body, attachmentList, mailServer, ref errorMsg, ref retError);
                    if (!string.IsNullOrEmpty(errorMsg))
                    {
                        throw new Exception(errorMsg);
                    }
                }
                #endregion

                return isSuccess;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        private bool SendEmailToReassignedApprover(string? approverName, string? approverEmail, string? ceaNo, string? ceaDescription)
        {
            bool isSuccess = false;

            try
            {
                var appSettingOptions = new AppSettingOptions();
                _config.GetSection(AppSettingOptions.AppSettings).Bind(appSettingOptions);

                #region Perform Validation
                //Check mail server
                string mailServer = appSettingOptions.GARMCOSMTP;
                if (string.IsNullOrEmpty(mailServer))
                    return false;
                #endregion

                #region Initialize variables
                int retError = 0;
                string errorMsg = string.Empty;
                string error = string.Empty;
                string innerError = string.Empty;
                #endregion

                #region Set the From, Subject, and primary recipients
                string adminAlias = appSettingOptions.AdminName;
                MailAddress from = new MailAddress(appSettingOptions.AdminEmail, !string.IsNullOrEmpty(adminAlias) ? adminAlias : "CEA System Administrator");
                string subject = $"CEA/MRE Requisition #{ceaNo} - {ceaDescription}";
                #endregion

                #region Set the Mail Recipients
                List<MailAddress> toList = null;
                List<MailAddress> ccList = null;
                List<MailAddress> bccList = null;

                #region Set the To recipients
                // Initialize the collection
                toList = new List<MailAddress>();

                if (!string.IsNullOrEmpty(approverEmail) &&
                    !string.IsNullOrEmpty(approverName))
                {
                    toList.Add(new MailAddress(approverEmail, _converter.ConvertStringToTitleCase(approverName)));
                }
                #endregion

                #region Set the Bcc recipients (For tracking purpose)
                if (!string.IsNullOrEmpty(appSettingOptions.WorkflowBccRecipients))
                {
                    string[] recipients = appSettingOptions.WorkflowBccRecipients.Split(';');
                    if (recipients != null && recipients.Count() > 0)
                    {
                        bccList = new List<MailAddress>();
                        foreach (string recipient in recipients)
                        {
                            if (recipient.Length > 0)
                                bccList.Add(new MailAddress(recipient, recipient));
                        }
                    }
                }
                #endregion

                #endregion

                // Exit if Mail-to recipient is null
                if (toList == null || toList.Count == 0)
                    return false;

                #region Set Message Body
                string body = String.Empty;
                string url = string.Format(@"{0}UserFunctions/Project/CEARequisition?requisitionNo={1}&actionType=3", appSettingOptions.SiteUrl, ceaNo);
                string adminName = appSettingOptions.AdminName;

                // Set the path of the xml message and the url
                string appPath = Environment.CurrentDirectory;
                if (Environment.CurrentDirectory.IndexOf("\\bin") > -1)
                    appPath = Environment.CurrentDirectory.Substring(0, Environment.CurrentDirectory.IndexOf("\\bin"));

                using (StreamReader reader = new StreamReader(appPath + @"\wwwroot\MailTemplates\NotifyReassignedApprover.html"))
                {
                    body = reader.ReadToEnd();
                }

                // Build the message body
                if (!string.IsNullOrEmpty(body))
                {
                    body = body.Replace("@1", _converter.ConvertStringToTitleCase(approverName!));
                    body = body.Replace("@2", ceaNo);
                    body = body.Replace("@3", url);
                    body = body.Replace("@4", ceaNo);
                }
                #endregion

                #region Create attachment
                List<Attachment> attachmentList = null;
                #endregion

                #region Send the e-mail
                if (!string.IsNullOrEmpty(body))
                {
                    retError = 0;
                    errorMsg = string.Empty;
                    SendEmail(toList, ccList, bccList, from, subject, body, attachmentList, mailServer, ref errorMsg, ref retError);
                    if (!string.IsNullOrEmpty(errorMsg))
                    {
                        throw new Exception(errorMsg);
                    }
                }
                #endregion

                return isSuccess;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        private void SendEmail(List<MailAddress> toList, List<MailAddress>? ccList, List<MailAddress>? bccList, MailAddress from,
            string subject, string body, List<Attachment>? attachmentList, string smtpConn, ref string errorMsg, ref int retError)
        {
            errorMsg = String.Empty;
            retError = 0;

            try
            {
                var appSettingOptions = new AppSettingOptions();
                _config.GetSection(AppSettingOptions.AppSettings).Bind(appSettingOptions);

                bool isTestMode = _converter.ConvertNumberToBolean(appSettingOptions.EmailTestMode);
                int indexLoc = 0;
                string newEmailAddress = string.Empty;

                // Create an email object
                MailMessage email = new MailMessage();

                #region Add all the recipients and originator
                if (toList != null)
                {
                    foreach (MailAddress to in toList)
                    {
                        if (isTestMode)
                        {
                            #region Append underscore to the email address if in test mode
                            if (!string.IsNullOrEmpty(to.Address))
                            {
                                indexLoc = to.Address.IndexOf("@");
                                if (indexLoc > 0)
                                {
                                    newEmailAddress = to.Address.Replace(to.Address.Substring(indexLoc + 1),
                                        string.Concat("_", to.Address.Substring(indexLoc + 1)));

                                    // Add email address
                                    email.To.Add(new MailAddress(newEmailAddress, to.DisplayName));
                                }
                                else
                                    email.To.Add(to);
                            }
                            #endregion
                        }
                        else
                            email.To.Add(to);
                    }
                }

                if (ccList != null)
                {
                    foreach (MailAddress cc in ccList)
                    {
                        if (isTestMode)
                        {
                            #region Append underscore to the email address if in test mode
                            if (!string.IsNullOrEmpty(cc.Address))
                            {
                                indexLoc = cc.Address.IndexOf("@");
                                if (indexLoc > 0)
                                {
                                    newEmailAddress = cc.Address.Replace(cc.Address.Substring(indexLoc + 1),
                                        string.Concat("_", cc.Address.Substring(indexLoc + 1)));

                                    // Add email address
                                    email.CC.Add(new MailAddress(newEmailAddress, cc.DisplayName));
                                }
                                else
                                    email.CC.Add(cc);
                            }
                            #endregion
                        }
                        else
                            email.CC.Add(cc);
                    }
                }

                if (bccList != null)
                {
                    foreach (MailAddress bcc in bccList)
                    {
                        email.Bcc.Add(bcc);
                    }
                }

                email.From = from;
                #endregion

                #region Set the subject and body
                email.Subject = subject;

                StringBuilder bodyList = new StringBuilder();
                bodyList.Append("<div style='font-family: Tahoma; font-size: 10pt'>");
                bodyList.Append(body);
                bodyList.Append("</div>");
                email.Body = bodyList.ToString();
                email.IsBodyHtml = true;
                #endregion

                #region Add attachments
                if (attachmentList != null)
                {
                    foreach (Attachment attach in attachmentList)
                        email.Attachments.Add(attach);
                }
                #endregion

                // Create an smtp client and send the mail message
                SmtpClient smtpClient = new SmtpClient(smtpConn);
                smtpClient.UseDefaultCredentials = true;

                // Send the mail message
                smtpClient.Send(email);

            }

            catch (Exception error)
            {
                errorMsg = error.Message;
                retError = -1;
            }
        }
        #endregion
    }
}
