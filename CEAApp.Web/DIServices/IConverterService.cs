using System.Globalization;

namespace CEAApp.Web.DIServices
{
    public interface IConverterService
    {
        #region Public Methods
        int ConvertObjectToInt(object value);
        short ConvertObjectToShort(object value);
        long ConvertObjectToLong(object value);
        double ConvertObjectToDouble(object value);
        decimal ConvertObjectToDecimal(object value);
        bool ConvertObjectToBoolean(object value);
        bool ConvertNumberToBolean(object value);
        byte ConvertObjectToByte(object value);
        DateTime? ConvertObjectToDate(object value);
        DateTime? ConvertObjectToDate(object value, CultureInfo ci);
        string ConvertObjectToString(object value);
        string ConvertStringToTitleCase(string input);
        string GetUserFirstName(string userName);
        #endregion
    }
}
