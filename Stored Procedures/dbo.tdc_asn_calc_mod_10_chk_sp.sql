SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create proc [dbo].[tdc_asn_calc_mod_10_chk_sp] (@bar_code_str varchar(63)) as

/*
 * Procedure to calculate the UCC-128 modulo 10 check character
 *
 * Input:
 *	- bar code number entered as a string of characters WITHOUT
 *	  any formatting.
 *
 *	  The bar code string should be 17 or fewer characters.
 *	  If the final modulo 10 check character (position 18) is
 *	  entered, it is removed.
 *
 *	Formatted barcode example (but do NOT pass it in this way):
 *		(00) 0 0740495 999999999 8
 *		 QQ  C MMMMMMM SSSSSSSSS m
 *
 *		Q = UCC 128 qualifier
 *		C = Carton type (0 = carton, 1 = palette)
 *		M = Manufacturer's code
 *		S = Serial Number
 *		m = Modulo 10 check digit
 *
 *	Do NOT include the (00) qualifier that indicates the barcode
 *	is a UCC 128 shipping container code.
 *
 * Output:
 *	- the final modulo 10 check character represented as an integer.
 *	  (because procs return only an optional integer value)
 *
 * 980623 REA
 *	proc creation based on algorithm located at
 *		http://www.uc-council.org/d33-b.htm
 */

set nocount on

DECLARE @position int,
	@sum_odd int,
	@sum_even int,
	@return_value int

SELECT @bar_code_str = RTRIM(LTRIM(@bar_code_str))

IF (DATALENGTH(@bar_code_str) > 17) 
	SELECT @bar_code_str = SUBSTRING(@bar_code_str, 1, 17)

SELECT @bar_code_str = RIGHT('00000000000000000'+@bar_code_str,17)

/*
 * Now the string is 17 characters long (assumed all numeric)
 * The algorithm describes the bar code in reverse order, so that
 * the first character is considered to be in position 18, the
 * 17th chracter is considered to be in position 2, and the last
 * character (the modulo 10 check character) is considered to be
 * in position 1.  Therefore, the odd and even positions will appear
 * to be reversed.
 */

SELECT	@position = 1,
	@sum_odd  = 0,
	@sum_even = 0

WHILE @position < 17 BEGIN
	SELECT @sum_even = @sum_even + convert(int, SUBSTRING(@bar_code_str, @position, 1))
	SELECT @sum_odd  = @sum_odd + convert(int, SUBSTRING(@bar_code_str, @position+1, 1))
	SELECT @position = @position + 2
	END
SELECT @sum_even = @sum_even + convert(int, SUBSTRING(@bar_code_str, @position, 1))

SELECT @return_value = (10 - ((3 * @sum_even + @sum_odd) % 10)) % 10

--SELECT '''+@bar_code_str+'' has modulo 10 check character of '+convert(varchar(10),@return_value)

return @return_value

GO
GRANT EXECUTE ON  [dbo].[tdc_asn_calc_mod_10_chk_sp] TO [public]
GO
