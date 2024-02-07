using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.Data.SqlClient;
using System.Data;
using CEAApp.Web.Models;
using CEAApp.Web.Helpers;
using Microsoft.EntityFrameworkCore;
using CEAApp.Web.DIServices;
using System.Data.Common;
using Dapper;

namespace CEAApp.Web.Repositories
{
    public class ExcelUploadRepository  : IExcelUploadRepository
    {

        #region Fields
        private readonly ApplicationDbContext _db;
        private readonly string? _connectionString;
        private readonly IConverterService _converter;
        private IDbConnection _dapperDB = null;
        private ExcelDataUpload _excelDataUpload;
        #endregion

        #region Constructors
        public ExcelUploadRepository(ApplicationDbContext context, IConfiguration configuration, IConverterService converter, ExcelDataUpload excelDataUpload)
        {
            _db = context;
            _connectionString = configuration.GetConnectionString("CEAConnectionString");
            _converter = converter;
            _excelDataUpload = excelDataUpload;
        }
        #endregion

        public async Task<int> SaveFromExcel(IFormFile projectFileName,EmployeeInfo? empInfo)
        {
            DBTransResult? dbResult = null;
            int rowsAffected = 0;
            List<Project> model = _excelDataUpload.ReadFromExcel(projectFileName,empInfo);

            try
            {
                using (_dapperDB = new SqlConnection(_connectionString))
                {
                    for (int i = 0; i < model.Count; i++)
                    {
                        string ExpCategory = GetPrefix(model[i].CategoryCode1.ToString()); //expense category content shortening
                        var parameters = new DynamicParameters();
                        parameters.Add("@ProjectNo", model[i].ProjectNo, DbType.String, ParameterDirection.Input);
                        parameters.Add("@FiscalYear", model[i].FiscalYear, DbType.Int16, ParameterDirection.Input);
                        parameters.Add("@ExpectedProjectDate", model[i].ExpectedProjectDate, DbType.DateTime, ParameterDirection.Input);
                        parameters.Add("@CompanyCode", model[i].CompanyCode, DbType.Int16, ParameterDirection.Input);                                //need to change
                        parameters.Add("@CostCenter", model[i].CostCenter, DbType.String, ParameterDirection.Input);
                        parameters.Add("@ExpenditureType", model[i].ExpenditureType, DbType.String, ParameterDirection.Input);
                        parameters.Add("@Description", model[i].Description, DbType.String, ParameterDirection.Input);
                        parameters.Add("@DetailDescription", model[i].DetailDescription, DbType.String, ParameterDirection.Input);
                        parameters.Add("@ProjectAmount", model[i].ProjectAmount, DbType.Decimal, ParameterDirection.Input);
                        parameters.Add("@AccountCode", model[i].AccountCode, DbType.String, ParameterDirection.Input);
                        parameters.Add("@Object", model[i].ObjectCode, DbType.String, ParameterDirection.Input);
                        parameters.Add("@Subject", model[i].SubjectCode, DbType.String, ParameterDirection.Input);
                        parameters.Add("@CategoryCode1", ExpCategory, DbType.String, ParameterDirection.Input);
                        parameters.Add("@CategoryCode2", model[i].CategoryCode2, DbType.String, ParameterDirection.Input);
                        parameters.Add("@CategoryCode3", model[i].CategoryCode3, DbType.String, ParameterDirection.Input);
                        parameters.Add("@CategoryCode4", model[i].CategoryCode4, DbType.String, ParameterDirection.Input);
                        parameters.Add("@CategoryCode5", model[i].CategoryCode5, DbType.String, ParameterDirection.Input);
                        parameters.Add("@CreateBy", empInfo.EmpName, DbType.String, ParameterDirection.Input);
                        parameters.Add("@LastUpdateBy", empInfo.EmpName, DbType.String, ParameterDirection.Input);

                        rowsAffected = _dapperDB.Execute("Projectuser.spInsertProjects", parameters, commandType: CommandType.StoredProcedure); // Save to database

                        if (rowsAffected > 0)
                        {

                            dbResult = new DBTransResult()
                            {
                                RowsAffected = rowsAffected,
                                HasError = false
                            };

                        }
                    }                    

                }

                return rowsAffected;
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message.ToString());
            }
        }

        /// <summary>
        /// Returns the prefix of a string passed. Eg. prefix 'WH' for 'Hellow World'
        /// </summary>
        /// <param name="value">String</param>
        /// <returns>Prefix value of the string</returns>
        public string GetPrefix(string value)
        {
            //string length counter
            int counter = 1;
            //break the string in to char array
            Char[] stringChar = value.ToCharArray();

            string createString = "";
            string prefixString = "";

            //traverse through the string to find words in the string
            foreach (Char charValue in stringChar)
            {
                //concatanage the characters to build the string
                createString = createString + charValue.ToString();
                //if empty space is found, then that's a word! 
                //length is checked to get the last word of the string
                if ((char.IsWhiteSpace(charValue)) || (value.Length.Equals(counter)) || (charValue.Equals(".")))
                {
                    //get the first character
                    createString = createString.Substring(0, 1);
                    //build the prefix
                    prefixString = prefixString + createString;
                    //start for the new word
                    createString = "";
                }
                counter++;
            }

            // return the created prefix
            return prefixString;
        }

    }
}
