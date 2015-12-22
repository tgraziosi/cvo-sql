SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

       
CREATE PROCEDURE [dbo].[icv_parse] @buf char(255), 
			   @trx_type char(2) OUTPUT,
			   @trx_ctrl_num char(17) OUTPUT,
			   @prompt1 char(255) OUTPUT,
			   @prompt2 char(255) OUTPUT,
			   @prompt3 char(255) OUTPUT,
			   @amt char(255) OUTPUT
AS

DECLARE @I  int
DECLARE @I1 int

/*
**
**   11   222222222222   333333333   444444444444444   5555   666666
**  "C4","Richard Sisk","ORD090021","378536800813005","0010","100.00"
**
**  1. @trx_type
**  2. @prompt1
**  3. @trx_ctrl_num
**  4. @prompt2
**  5. @prompt3
**  6. @amt
*/

SELECT @trx_type = NULL, @prompt1 = NULL, @trx_ctrl_num = NULL, @prompt2 = NULL, @prompt3 = NULL, @amt = NULL


/*
** Parse out trx_type
*/ 
IF SUBSTRING(@buf, 1, 1) <> """"
	RETURN -1010
IF SUBSTRING(@buf, 4, 1) <> """"
	RETURN -1020
IF SUBSTRING(@buf, 5, 1) <> ","
	RETURN -1030

SELECT @I = 2
SELECT @I1 = CHARINDEX("""", SUBSTRING(@buf, @I, 255))
SELECT @trx_type = SUBSTRING(@buf, @I, (@I1 - @I)+1 )



/*
** Parse out prompt1
**  "C4","Richard Sisk","ORD090021","378536800813005","0010","100.00"
*/ 
IF SUBSTRING(@buf, 6, 1) <> """"
	RETURN -1040

SELECT @I = 7
SELECT @I1 = CHARINDEX("""", SUBSTRING(@buf, @I, 255))
IF @I1 = 0
	RETURN -1050

SELECT @prompt1 = SUBSTRING(@buf, @I, @I1-1 )



/*
** Parse out trx_ctrl_num
**  "C4","Richard Sisk","ORD090021","378536800813005","0010","100.00"
*/ 
IF SUBSTRING(@buf, 6, 1) <> """"
	RETURN -1040

SELECT @I = 7
SELECT @I = CHARINDEX("""", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1050
SELECT @I = CHARINDEX(",", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1060
SELECT @I = CHARINDEX("""", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1070
SELECT @I1 = CHARINDEX("""", SUBSTRING(@buf, @I, 255))
IF @I1 = 0
	RETURN -1080

SELECT @trx_ctrl_num = SUBSTRING(@buf, @I, @I1-1 )



/*
** Parse out prompt2
**  "C4","Richard Sisk","ORD090021","378536800813005","0010","100.00"
*/ 
IF SUBSTRING(@buf, 6, 1) <> """"
	RETURN -1040

SELECT @I = 7
SELECT @I = CHARINDEX("""", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1050
SELECT @I = CHARINDEX(",", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1060
SELECT @I = CHARINDEX("""", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1070
SELECT @I = CHARINDEX(",", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1080
SELECT @I = CHARINDEX("""", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1090
SELECT @I1 = CHARINDEX("""", SUBSTRING(@buf, @I, 255))
IF @I1 = 0
	RETURN -1100

SELECT @prompt2 = SUBSTRING(@buf, @I, @I1-1 )



/*
** Parse out prompt3
**  "C4","Richard Sisk","ORD090021","378536800813005","0010","100.00"
*/ 
IF SUBSTRING(@buf, 6, 1) <> """"
	RETURN -1040

SELECT @I = 7
SELECT @I = CHARINDEX("""", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1050
SELECT @I = CHARINDEX(",", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1060
SELECT @I = CHARINDEX("""", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1070
SELECT @I = CHARINDEX(",", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1080
SELECT @I = CHARINDEX("""", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1090
SELECT @I = CHARINDEX(",", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1100
SELECT @I = CHARINDEX("""", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1110
SELECT @I1 = CHARINDEX("""", SUBSTRING(@buf, @I, 255))
IF @I1 = 0
	RETURN -1120

SELECT @prompt3 = SUBSTRING(SUBSTRING(@buf, @I, @I1-1 ),3,2) + "/" + SUBSTRING(SUBSTRING(@buf, @I, @I1-1 ),1,2) 



/*
** Parse out amt
**  "C4","Richard Sisk","ORD090021","378536800813005","0010","100.00"
*/ 
IF SUBSTRING(@buf, 6, 1) <> """"
	RETURN -1040

SELECT @I = 7
SELECT @I = CHARINDEX("""", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1050
SELECT @I = CHARINDEX(",", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1060
SELECT @I = CHARINDEX("""", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1070
SELECT @I = CHARINDEX(",", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1080
SELECT @I = CHARINDEX("""", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1090
SELECT @I = CHARINDEX(",", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1100
SELECT @I = CHARINDEX("""", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1110
SELECT @I = CHARINDEX(",", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1120
SELECT @I = CHARINDEX("""", SUBSTRING(@buf, @I, 255)) + @I
IF @I = 0
	RETURN -1130
SELECT @I1 = CHARINDEX("""", SUBSTRING(@buf, @I, 255))
IF @I1 = 0
	RETURN -1140

SELECT @amt = SUBSTRING(@buf, @I, @I1-1 )



RETURN 0
GO
GRANT EXECUTE ON  [dbo].[icv_parse] TO [public]
GO
