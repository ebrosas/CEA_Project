using Microsoft.Data.SqlClient;
using System.Data;

namespace CEAApp.Web.Models
{
    public class ADONetParameter
    {
        #region Members
        protected SqlParameter InternalParameter;
        #endregion

        #region Constructors
        public ADONetParameter()
        {
            this.InternalParameter = new SqlParameter();
        }

        public ADONetParameter(string parameterName, SqlDbType parameterType)
            : this()
        {
            this.InternalParameter.ParameterName = parameterName;
            this.InternalParameter.SqlDbType = parameterType;
        }

        public ADONetParameter(string parameterName, SqlDbType parameterType, object parameterValue)
            : this()
        {
            this.InternalParameter.ParameterName = parameterName;
            this.InternalParameter.SqlDbType = parameterType;
            this.InternalParameter.Value = parameterValue;
        }

        public ADONetParameter(string parameterName, SqlDbType parameterType, int parameterSize, object parameterValue)
            : this()
        {
            this.InternalParameter.ParameterName = parameterName;
            this.InternalParameter.SqlDbType = parameterType;
            this.InternalParameter.Size = parameterSize;
            this.InternalParameter.Value = parameterValue;
        }

        #endregion

        #region Properties

        public object ParameterValue
        {
            get
            {
                return this.InternalParameter.Value;
            }
            set
            {
                this.InternalParameter.Value = value;
            }
        }

        public SqlParameter Parameter
        {
            get
            {
                return this.InternalParameter;
            }
        }

        public string ParameterName
        {
            get
            {
                return this.InternalParameter.ParameterName;
            }
            set
            {
                this.InternalParameter.ParameterName = value;
            }
        }

        public SqlDbType ParameterType
        {
            get
            {
                return this.InternalParameter.SqlDbType;
            }
            set
            {
                this.InternalParameter.SqlDbType = value;
            }
        }

        public int ParameterSize
        {
            get
            {
                return this.InternalParameter.Size;
            }
            set
            {
                this.InternalParameter.Size = value;
            }
        }

        #endregion
    }
}
