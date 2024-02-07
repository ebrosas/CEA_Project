using System.Globalization;
using System.Text.RegularExpressions;

namespace CEAApp.Web.DIServices
{
    public class ConverterService : IConverterService
    {
        #region Interface Implementation 
        public bool ConvertNumberToBolean(object value)
        {
            if (value != null && Convert.ToInt32(value) == 1)
                return true;
            else
                return false;
        }

        public bool ConvertObjectToBoolean(object value)
        {
            bool result;
            if (value != null && bool.TryParse(value.ToString(), out result))
                return result;
            else
                return false;
        }

        public decimal ConvertObjectToDecimal(object value)
        {
            decimal result;
            if (value != null && decimal.TryParse(value.ToString(), out result))
                return result;
            else
                return 0;
        }

        public double ConvertObjectToDouble(object value)
        {
            double result;
            if (value != null && double.TryParse(value.ToString(), out result))
                return result;
            else
                return 0;
        }

        public int ConvertObjectToInt(object value)
        {
            int result;
            if (value != null && int.TryParse(value.ToString(), out result))
                return result;
            else
                return 0;
        }

        public long ConvertObjectToLong(object value)
        {
            long result;
            if (value != null && long.TryParse(value.ToString(), out result))
                return result;
            else
                return 0;
        }

        public byte ConvertObjectToByte(object value)
        {
            byte result;
            if (value != null && byte.TryParse(value.ToString(), out result))
                return result;
            else
                return 0;
        }

        public DateTime? ConvertObjectToDate(object value)
        {
            if (Thread.CurrentThread.CurrentUICulture.Name.Trim() != "en-GB")
            {
                Thread.CurrentThread.CurrentCulture = new CultureInfo("en-GB");
            }

            DateTime result;
            if (value != null && DateTime.TryParse(value.ToString(), out result))
                return result;
            else
                return null;
        }

        public DateTime? ConvertObjectToDate(object value, CultureInfo ci)
        {
            if (ci.Name.Trim() != "en-GB")
            {
                Thread.CurrentThread.CurrentCulture = new CultureInfo("en-GB");
            }

            DateTime result;
            if (value != null && DateTime.TryParse(value.ToString(), out result))
                return result;
            else
                return null;
        }

        public string ConvertObjectToString(object value)
        {
            return value != null ? value.ToString().Trim() : string.Empty;
        }

        public string ConvertStringToTitleCase(string input)
        {
            if (string.IsNullOrEmpty(input))
                return string.Empty;

            System.Globalization.CultureInfo cultureInfo = System.Threading.Thread.CurrentThread.CurrentCulture;
            System.Globalization.TextInfo textInfo = cultureInfo.TextInfo;
            return textInfo.ToTitleCase(input.ToLower().Trim());
        }

        public string GetUserFirstName(string userName)
        {
            if (string.IsNullOrEmpty(userName))
                return string.Empty;

            try
            {
                string result = string.Empty;
                Match m = Regex.Match(userName, @"(\w*) (\w.*)");
                string firstName = m.Groups[1].ToString();

                if (!string.IsNullOrEmpty(firstName))
                {
                    System.Globalization.CultureInfo cultureInfo = System.Threading.Thread.CurrentThread.CurrentCulture;
                    System.Globalization.TextInfo textInfo = cultureInfo.TextInfo;
                    result = textInfo.ToTitleCase(firstName.ToLower().Trim());
                }

                return result;
            }
            catch (Exception)
            {
                return string.Empty;
            }
        }

        public short ConvertObjectToShort(object value)
        {
            short result;
            if (value != null && short.TryParse(value.ToString(), out result))
                return result;
            else
                return 0;
        }
        #endregion
    }
}
