using System.Data;
using System.Data.OleDb;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.Data.SqlClient;
using CEAApp.Web.Models;
using CEAApp.Web.Helpers;
using Microsoft.EntityFrameworkCore;
using CEAApp.Web.DIServices;
using ExcelDataReader;

namespace CEAApp.Web.Helpers
{
    public class ExcelDataUpload
    {
        private readonly IConverterService _converter;

        #region Constructors
        public ExcelDataUpload(IConverterService converter)
        {
            _converter = converter;
        }
        #endregion

        // reading the excel content
        public List<Project> ReadFromExcel(IFormFile uploadFile, EmployeeInfo? empInfo)
        {
            try
            {
                IExcelDataReader excelReader = null;
                Stream FileStream = null;
                FileStream = uploadFile.OpenReadStream();

                if (uploadFile != null && FileStream != null)
                {
                    excelReader = ExcelReaderFactory.CreateReader(FileStream);
                }

                if (excelReader != null)
                {
                    DataSet result = excelReader.AsDataSet();
                    if (result != null && result.Tables.Count > 0)
                    {
                        var model = DataTableToJSON(result.Tables[0], empInfo);
                        return model;
                    }
                }

                return null;
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Source + "\n" + ex.Message);
            }
        }

        public List<Project> DataTableToJSON(DataTable table, EmployeeInfo? empInfo)
        {
            try
            {
                List<Project> list = null;
                if (table.Rows.Count > 0)
                {
                    list = new List<Project>();
                    //skiping the first row, table Header 
                    foreach (var item in table.Rows.Cast<DataRow>().Skip(1))
                    {
                        list.Add(new Project()
                        {
                            FiscalYear =  _converter.ConvertObjectToShort(item.ItemArray[0]!),
                            ExpenditureType = _converter.ConvertObjectToString(((DataRow)item).ItemArray[1]!),
                            CostCenter = _converter.ConvertObjectToString(((DataRow)item).ItemArray[2]!),
                            ProjectNo = _converter.ConvertObjectToString(((DataRow)item).ItemArray[3]!),
                            CategoryCode1 = _converter.ConvertObjectToString(((DataRow)item).ItemArray[4]!),
                            Description = _converter.ConvertObjectToString(((DataRow)item).ItemArray[5]!),
                            DetailDescription = _converter.ConvertObjectToString(((DataRow)item).ItemArray[6]!),
                            ProjectAmount = _converter.ConvertObjectToDecimal(((DataRow)item).ItemArray[7] ?? 0.0),
                            AccountCode = _converter.ConvertObjectToString(((DataRow)item).ItemArray[8] ?? 0.0),
                            ObjectCode = _converter.ConvertObjectToString(((DataRow)item).ItemArray[9] ?? 0.0),
                            SubjectCode = _converter.ConvertObjectToString(((DataRow)item).ItemArray[10] ?? 0.0),
                            CompanyCode = _converter.ConvertObjectToShort(((DataRow)item).ItemArray[11] ?? 0),
                            ExpectedProjectDate = (DateTime)_converter.ConvertObjectToDate(item.ItemArray[12]!)!,

                            CategoryCode2 = "",
                            CategoryCode3 = "",
                            CategoryCode4 = "",
                            CategoryCode5 = "",
                            CreateBy = empInfo!.EmpName,
                            LastUpdateBy = empInfo.EmpName,
                        });
                    }
                }

                return list;
            }
            catch(Exception ex)
            {
                throw new Exception(ex.Message, ex);
            }
        }
    }
        
}
