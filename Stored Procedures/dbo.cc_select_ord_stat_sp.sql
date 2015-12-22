SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_select_ord_stat_sp] 

AS
	DECLARE @a tinyint,
		@b tinyint,
		@c tinyint,
		@e tinyint,
		@h tinyint,
		@m tinyint,
		@n tinyint,
		@p tinyint,
		@q tinyint,
		@r tinyint,
		@s tinyint,
		@t tinyint,
		@v tinyint,
		@x tinyint,
		@returns	tinyint

	SELECT @a = use_flag FROM cc_ord_status WHERE upper(status_code) = 'A'
	SELECT @b = use_flag FROM cc_ord_status WHERE upper(status_code) = 'B'
	SELECT @c = use_flag FROM cc_ord_status WHERE upper(status_code) = 'C'
	SELECT @e = use_flag FROM cc_ord_status WHERE upper(status_code) = 'E'
	SELECT @h = use_flag FROM cc_ord_status WHERE upper(status_code) = 'H'
	SELECT @m = use_flag FROM cc_ord_status WHERE upper(status_code) = 'M'
	SELECT @n = use_flag FROM cc_ord_status WHERE upper(status_code) = 'N'
	SELECT @p = use_flag FROM cc_ord_status WHERE upper(status_code) = 'P'
	SELECT @q = use_flag FROM cc_ord_status WHERE upper(status_code) = 'Q'
	SELECT @r = use_flag FROM cc_ord_status WHERE upper(status_code) = 'R'
	SELECT @s = use_flag FROM cc_ord_status WHERE upper(status_code) = 'S'
	SELECT @t = use_flag FROM cc_ord_status WHERE upper(status_code) = 'T'
	SELECT @v = use_flag FROM cc_ord_status WHERE upper(status_code) = 'V'
	SELECT @x = use_flag FROM cc_ord_status WHERE upper(status_code) = 'X'
	SELECT @returns = include_credit_returns FROM cc_ord_status

	SELECT @a,@b,@c,@e,@h,@m,@n,@p,@q,@r,@s,@t,@v,@x, @returns

GO
GRANT EXECUTE ON  [dbo].[cc_select_ord_stat_sp] TO [public]
GO
