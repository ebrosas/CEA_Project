using CEAApp.Web.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace CEAApp.Web.Repositories
{
    public interface IADONetExtension
    {
        #region Public methods
        SqlParameter AddParameter(SqlCommand command, string parameterName, SqlDbType dbType, ParameterDirection direction);
        SqlParameter AddParameter(SqlCommand command, string parameterName, SqlDbType dbType, ParameterDirection direction, object parameterValue);
        SqlParameter AddParameter(SqlCommand command, string parameterName, SqlDbType dbType, ParameterDirection direction, object parameterValue, int parameterSize);
        DataSet RunSPReturnDataset(string spName, string connectionString, params ADONetParameter[] parameters);
        void CompileParameters(SqlCommand comm, ADONetParameter[] parameters);
        #endregion
    }
}
