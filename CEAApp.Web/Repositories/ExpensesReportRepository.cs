using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.Data.SqlClient;
using System.Data;
using CEAApp.Web.Models;
using CEAApp.Web.Helpers;
using Microsoft.EntityFrameworkCore;
using CEAApp.Web.DIServices;
using System.Data.Common;

namespace CEAApp.Web.Repositories
{
    public class ExpensesReportRepository : IExpensesReportRepository
    {

        private readonly ApplicationDbContext context;
        private readonly string _connectionString;
        private readonly IConverterService _converter;

        public ExpensesReportRepository(ApplicationDbContext context, IConfiguration configuration, IConverterService converter)
        {
            this.context = context;
            this._connectionString = configuration.GetConnectionString("CEAConnectionString");
            _converter = converter;
        }

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
                List<EmployeeInfo> employeeList = new List<EmployeeInfo>();
                DbCommand cmd;
                DbDataReader reader;

                string sql = "EXEC Projectuser.Pr_GetLookupTable @objectCode";

                // Build the command object
                cmd = context.Database.GetDbConnection().CreateCommand();
                cmd.CommandText = sql;

                // Create parameters
                cmd.Parameters.Add(new SqlParameter { ParameterName = "@objectCode", SqlDbType = SqlDbType.VarChar, Size = 20, Value = objectCode });

                // Open database connection
                await context.Database.OpenConnectionAsync();

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
                throw new Exception(ex.Message.ToString());
            }
        }
        #endregion

        public async Task<List<ExpensesReport>> ExpensesReportList(string costCenter, string expenditureType, int? fromFiscalYear, int? toFiscalYear, string projectStatusId, int requisitionStatusId, int? startRowIndex, int? maximumRows)
        {
            try
            {
                List<ExpensesReport> list = null;
                using (SqlConnection conn = new SqlConnection(_connectionString))
                {
                    using (SqlCommand cmd = new SqlCommand("Projectuser.spReport_CEAExpenses", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;

                        #region Create parameters
                        cmd.Parameters.Add(new SqlParameter { ParameterName = "@costCenter", SqlDbType = SqlDbType.VarChar, Value = costCenter });
                        cmd.Parameters.Add(new SqlParameter { ParameterName = "@expenditureType", SqlDbType = SqlDbType.VarChar, Value = expenditureType });
                        cmd.Parameters.Add(new SqlParameter { ParameterName = "@fromFiscalYear", SqlDbType = SqlDbType.Int, Value = fromFiscalYear });
                        cmd.Parameters.Add(new SqlParameter { ParameterName = "@toFiscalYear", SqlDbType = SqlDbType.Int, Value = toFiscalYear });
                        cmd.Parameters.Add(new SqlParameter { ParameterName = "@projectStatusId", SqlDbType = SqlDbType.VarChar, Value = projectStatusId });
                        cmd.Parameters.Add(new SqlParameter { ParameterName = "@requisitionStatusIds", SqlDbType = SqlDbType.Int, Value = requisitionStatusId });
                        cmd.Parameters.Add(new SqlParameter { ParameterName = "@FromRowNumber", SqlDbType = SqlDbType.TinyInt, Value = startRowIndex });
                        cmd.Parameters.Add(new SqlParameter { ParameterName = "@ToRowNumber", SqlDbType = SqlDbType.Int, Value = maximumRows });

                        #endregion

                        // Open the database connection
                        await conn.OpenAsync();

                        using (var reader = await cmd.ExecuteReaderAsync())
                        {
                            if (reader.HasRows)
                            {
                                // Initialize collection
                                list = new List<ExpensesReport>();

                                while (await reader.ReadAsync())
                                {
                                    var row = new ExpensesReport()
                                    {
                                        ProjectNo = _converter.ConvertObjectToString(reader["ProjectNo"]),
                                        CostCenter = _converter.ConvertObjectToString(reader["CostCenter"]),
                                        ExpenditureType = _converter.ConvertObjectToString(reader["ExpenditureType"]),
                                        FiscalYear = _converter.ConvertObjectToInt(reader["FiscalYear"]),
                                        ProjectStatus = _converter.ConvertObjectToString(reader["ProjectStatus"]),
                                        RequisitionNo = _converter.ConvertObjectToString(reader["RequisitionNo"]),
                                        RequisitionDate = _converter.ConvertObjectToDate(reader["RequisitionDate"]),
                                        Budget = _converter.ConvertObjectToDecimal(reader["Budget"]),
                                        RequisitionDescription = _converter.ConvertObjectToString(reader["RequisitionDescription"]),
                                        RequisitionStatus = _converter.ConvertObjectToString(reader["RequisitionStatus"]),
                                        OpenAmount = _converter.ConvertObjectToDecimal(reader["OpenAmount"]),
                                        GlAmount = _converter.ConvertObjectToDecimal(reader["GlAmount"]),
                                        Balance = _converter.ConvertObjectToDecimal(reader["Balance"])
                                    };

                                    list.Add(row);
                                }
                            }
                        }
                    }
                }

                return list;
            }
            catch (SqlException sqlErr)
            {
                throw new Exception(sqlErr.Message.ToString());
            }
        }

        public async Task<List<ExpensesReport>> LoadExpenseReportAsync(string costCenter, string expenditureType, int? fromFiscalYear, int? toFiscalYear, string projectStatusId, int requisitionStatusId, int? startRowIndex, int? maximumRows)
        {
            try
            {
                List<ExpensesReport> list = null;
                using (SqlConnection conn = new SqlConnection(_connectionString))
                {
                    using (SqlCommand cmd = new SqlCommand("Projectuser.spReport_CEAExpenses", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;

                        #region Create parameters
                        cmd.Parameters.Add(new SqlParameter { ParameterName = "FromRowNumber", SqlDbType = SqlDbType.Int, Value = startRowIndex != 0 ? startRowIndex : 0 });
                        cmd.Parameters.Add(new SqlParameter { ParameterName = "ToRowNumber", SqlDbType = SqlDbType.Int, Value = maximumRows != 0 ? maximumRows : 0 });
                        cmd.Parameters.Add(new SqlParameter { ParameterName = "CostCenter", SqlDbType = SqlDbType.VarChar, Value = costCenter ?? "" });
                        cmd.Parameters.Add(new SqlParameter { ParameterName = "ExpenditureType", SqlDbType = SqlDbType.VarChar, Value = expenditureType ?? "" });
                        cmd.Parameters.Add(new SqlParameter { ParameterName = "requisitionStatusId", SqlDbType = SqlDbType.Int, Value = requisitionStatusId });
                        cmd.Parameters.Add(new SqlParameter { ParameterName = "FromFiscalYear", SqlDbType = SqlDbType.Int, Value = fromFiscalYear ?? 0 });
                        cmd.Parameters.Add(new SqlParameter { ParameterName = "ToFiscalYear", SqlDbType = SqlDbType.Int, Value = toFiscalYear ?? 0 });
                        cmd.Parameters.Add(new SqlParameter { ParameterName = "projectStatusId", SqlDbType = SqlDbType.VarChar, Value = projectStatusId ?? string.Empty });
                        #endregion

                        // Open the database connection
                        await conn.OpenAsync();

                        using (var reader = await cmd.ExecuteReaderAsync())
                        {
                            if (reader.HasRows)
                            {
                                // Initialize collection
                                list = new List<ExpensesReport>();

                                while (await reader.ReadAsync())
                                {
                                    var row = new ExpensesReport()
                                    {
                                        ProjectNo = _converter.ConvertObjectToString(reader["ProjectNo"]),
                                        CostCenter = _converter.ConvertObjectToString(reader["CostCenter"]),
                                        ExpenditureType = _converter.ConvertObjectToString(reader["ExpenditureType"]),
                                        FiscalYear = _converter.ConvertObjectToInt(reader["FiscalYear"]),
                                        ProjectStatus = _converter.ConvertObjectToString(reader["ProjectStatus"]),
                                        RequisitionNo = _converter.ConvertObjectToString(reader["RequisitionNo"]),
                                        RequisitionDate = _converter.ConvertObjectToDate(reader["RequisitionDate"]),
                                        Budget = _converter.ConvertObjectToDecimal(reader["Budget"]),
                                        RequisitionDescription = _converter.ConvertObjectToString(reader["RequisitionDescription"]),
                                        RequisitionStatus = _converter.ConvertObjectToString(reader["RequisitionStatus"]),
                                        OpenAmount = _converter.ConvertObjectToDecimal(reader["OpenAmount"]),
                                        GlAmount = _converter.ConvertObjectToDecimal(reader["GlAmount"]),
                                        Balance = _converter.ConvertObjectToDecimal(reader["Balance"])
                                    };

                                    list.Add(row);
                                }
                            }
                        }
                    }
                }

                return list;
            }
            catch (SqlException sqlErr)
            {
                throw new Exception(sqlErr.Message.ToString());
            }
        }

        public async Task<List<DetailedExpensesReport>> LoadDetailedExpenseReportAsync(string costCenter, string expenditureType, int? fromFiscalYear, int? toFiscalYear, string projectStatusId, int requisitionStatusId, int? startRowIndex, int? maximumRows)
        {
            try
            {
                try
                {
                    List<DetailedExpensesReport> list = null;
                    string sql = "EXEC Projectuser.Pr_Report_CEADetailedExpenses @FromRowNumber, @ToRowNumber, @CostCenter, @ExpenditureType, @FromFiscalYear, @ToFiscalYear,@ProjectStatusId,@RequisitionStatusId";

                    List<SqlParameter> parms = new List<SqlParameter>
                        {
                            // Create parameters
                            new SqlParameter { ParameterName = "@FromRowNumber", SqlDbType = SqlDbType.Int, Value = startRowIndex },
                            new SqlParameter { ParameterName = "@ToRowNumber", SqlDbType = SqlDbType.Int, Value = maximumRows },
                            new SqlParameter { ParameterName = "@CostCenter", SqlDbType = SqlDbType.VarChar, Value = costCenter ?? "" },
                            new SqlParameter { ParameterName = "@ExpenditureType", SqlDbType = SqlDbType.VarChar, Value = expenditureType ?? "" },
                            new SqlParameter { ParameterName = "@FromFiscalYear", SqlDbType = SqlDbType.Int, Value = Convert.ToInt32(fromFiscalYear)},
                            new SqlParameter { ParameterName = "@ToFiscalYear", SqlDbType = SqlDbType.Int, Value = Convert.ToInt32(toFiscalYear) },
                            new SqlParameter { ParameterName = "@ProjectStatusId", SqlDbType = SqlDbType.VarChar, Value = projectStatusId },
                            new SqlParameter { ParameterName = "@RequisitionStatusId", SqlDbType = SqlDbType.Int, Value = requisitionStatusId },
                    };

                    list = await context.DetailedExpensesReport
                        .FromSqlRaw(sql, parms.ToArray())
                        .ToListAsync();

                    return list;
                }
                catch (Exception ex)
                {
                    throw new Exception(ex.Message.ToString());
                }
            }
            catch (SqlException sqlErr)
            {
                throw new Exception(sqlErr.Message.ToString());
            }
        }

        #region Requisition Report
        public async Task<List<RequisitionReport>> LoadRequisitionReportAsync(string costCenter, string expenditureType, int? fromFiscalYear, int? toFiscalYear, string projectStatusId, int requisitionStatusId, int? startRowIndex, int? maximumRows)
        {
            try
            {
                List<RequisitionReport> list = null;
                //string sql = "EXEC Projectuser.spReport_CEARequisitions @FromRowNumber, @ToRowNumber, @CostCenter, @ExpenditureType, @FromFiscalYear, @ToFiscalYear, @RequisitionStatusId";
                string sql = "EXEC Projectuser.Pr_Report_CEARequisitions @CostCenter, @ExpenditureType, @RequisitionStatusId, @FromFiscalYear, @ToFiscalYear";

                List<SqlParameter> parms = new List<SqlParameter>
                        {
                            // Create parameters
                            //new SqlParameter { ParameterName = "@FromRowNumber", SqlDbType = SqlDbType.Int, Value = startRowIndex },
                            //new SqlParameter { ParameterName = "@ToRowNumber", SqlDbType = SqlDbType.Int, Value = maximumRows },
                            new SqlParameter { ParameterName = "@CostCenter", SqlDbType = SqlDbType.VarChar, Value = costCenter ?? "" },
                            new SqlParameter { ParameterName = "@ExpenditureType", SqlDbType = SqlDbType.VarChar, Value = expenditureType ?? ""},
                            new SqlParameter { ParameterName = "@RequisitionStatusId", SqlDbType = SqlDbType.Int, Value = requisitionStatusId },
                            new SqlParameter { ParameterName = "@FromFiscalYear", SqlDbType = SqlDbType.Int, Value = Convert.ToInt32(fromFiscalYear)},
                            new SqlParameter { ParameterName = "@ToFiscalYear", SqlDbType = SqlDbType.Int, Value = Convert.ToInt32(toFiscalYear) },
                            //new SqlParameter { ParameterName = "@ProjectStatusId", SqlDbType = SqlDbType.VarChar, Value = projectStatusId },

                    };

                list = await context.RequisitionReport
                    .FromSqlRaw(sql, parms.ToArray())
                    .ToListAsync();

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
            finally{
                
            }
        }

        /// <summary>
        /// Printing the Requisitions
        /// </summary>
        /// <param name="RequisitionNo"></param>
        /// <returns></returns>
        /// <exception cref="Exception"></exception>
        public async Task<List<RequisitionPrint>> LoadRequisitionPrintAsync(int RequisitionNo)
        {
            try
            {
                List<RequisitionPrint> list = null;
                string sql = "EXEC Projectuser.spReport_Requisition @RequisitionNo";

                List<SqlParameter> parms = new List<SqlParameter>
                        {
                            // Create parameters
                            new SqlParameter { ParameterName = "@RequisitionNo", SqlDbType = SqlDbType.VarChar, Value = RequisitionNo },
                        };

                list = await context.RequisitionPrint
                    .FromSqlRaw(sql, parms.ToArray())
                    .ToListAsync();

                return list;
            }
            catch (SqlException sqlErr)
            {
                throw new Exception(sqlErr.Message.ToString());
            }
            // catch ArgumentException
            catch (ArgumentException ex)
            {
                throw new Exception(ex.Message.ToString());
            }
            // catch all others
            catch (Exception ex)
            {
                throw new Exception(ex.Message.ToString());
            }
        }

        public async Task<List<RequisitionApprover>> LoadRequisitionApproverPrintAsync(int RequisitionNo)
        {
            try
            {
                List<RequisitionApprover> list = null;
                string sql = "EXEC Projectuser.pr_RequisitionApprovers @RequisitionNo";

                List<SqlParameter> parms = new List<SqlParameter>
                        {
                            // Create parameters
                            new SqlParameter { ParameterName = "@RequisitionNo", SqlDbType = SqlDbType.VarChar, Value = RequisitionNo },
                        };

                list = await context.RequisitionApprover
                    .FromSqlRaw(sql, parms.ToArray())
                    .ToListAsync();

                return list;
            }
            catch (SqlException sqlErr)
            {
                throw new Exception(sqlErr.Message.ToString());
            }
            // catch ArgumentException
            catch (ArgumentException ex)
            {
                throw new Exception(ex.Message.ToString());
            }
            // catch all others
            catch (Exception ex)
            {
                throw new Exception(ex.Message.ToString());
            }
        }
        
        public async Task<List<RequisitionExpense>> LoadRequisitionExpensesPrintAsync(int RequisitionNo)
        {
            try
            {
                List<RequisitionExpense> list = null;
                string sql = "EXEC Projectuser.pr_RequisitionExpenses @RequisitionNo";

                List<SqlParameter> parms = new List<SqlParameter>
                        {
                            // Create parameters
                            new SqlParameter { ParameterName = "@RequisitionNo", SqlDbType = SqlDbType.VarChar, Value = RequisitionNo },
                        };

                list = await context.RequisitionExpense
                    .FromSqlRaw(sql, parms.ToArray())
                    .ToListAsync();

                return list;
            }
            catch (SqlException sqlErr)
            {
                throw new Exception(sqlErr.Message.ToString());
            }
            // catch ArgumentException
            catch (ArgumentException ex)
            {
                throw new Exception(ex.Message.ToString());
            }
            // catch all others
            catch (Exception ex)
            {
                throw new Exception(ex.Message.ToString());
            }
        }
        #endregion
    }
    
}
