SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[date_as_canadian_format_fn] ( @jul_date int, @opcion int )
RETURNS @myTable TABLE (formated_date varchar(16), format_date varchar(16))
as
BEGIN
	declare @date varchar(10)
	declare @mes varchar(8)
	declare @dia varchar(8)
	declare @ano varchar(8)
	select @date = CONVERT ( varchar(10), dateadd(day,(@jul_date - 711858),'1/1/1950') , 101 )
	select	@mes = SUBSTRING ( @date , 1 , 1 ) + ' ' + SUBSTRING ( @date , 2 , 1 ) + ' ', 
		@dia = SUBSTRING ( @date , 4 , 1 ) + ' ' + SUBSTRING ( @date , 5 , 1 ) + ' ', 
		@ano = SUBSTRING ( @date , 7 , 1 ) + ' ' + SUBSTRING ( @date , 8 , 1 ) + ' '
			+ SUBSTRING ( @date , 9 , 1 ) + ' ' + SUBSTRING ( @date , 10 , 1 ) + ' '

	insert into @myTable (formated_date , format_date )
	select case when @opcion = 1 then @mes + @dia + @ano
		when @opcion = 2 then @ano + @mes + @dia 
		else @dia + @mes + @ano end formated_date , 
	case when @opcion = 1 then 'M M D D Y Y Y Y'
		when @opcion = 2 then 'Y Y Y Y M M D D'
		else 'D D M M Y Y Y Y' end format_date
	return 
END

GO
GRANT REFERENCES ON  [dbo].[date_as_canadian_format_fn] TO [public]
GO
GRANT SELECT ON  [dbo].[date_as_canadian_format_fn] TO [public]
GO
