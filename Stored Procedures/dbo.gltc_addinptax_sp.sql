SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                










CREATE PROCEDURE [dbo].[gltc_addinptax_sp]
	@tablename  varchar(255),
	@trx_ctrl_num varchar(16),
	@trx_type smallint,
	@sequence_id int,
	@detail_sequence_id int,
	@tax_type_code varchar(8),
	@amt_taxable float,
	@amt_gross   float,
	@amt_tax     float,
	@amt_final_tax float,
	@account_code	varchar(32),
	@debug_level  smallint = 0,
	@p_form_id	int=0		
WITH RECOMPILE
AS

declare @recoverable_flag int
declare @tmp_amt_final_tax1 float
DECLARE @sqlworkstring	varchar(8000)
DECLARE @p_form_id_char	varchar(250)

if isnull(@p_form_id,0) != 0
	SELECT @p_form_id_char = cast(@p_form_id as varchar(20))
else
	SELECT @p_form_id_char = '0000'

if @tablename = 'arinptax' 
begin
	if not exists(SELECT 1 FROM arinptax 
			WHERE trx_ctrl_num = @trx_ctrl_num 
			AND trx_type = @trx_type 
			AND tax_type_code = @tax_type_code )
		INSERT arinptax (trx_ctrl_num, trx_type, sequence_id, tax_type_code, amt_taxable, amt_gross, amt_tax, amt_final_tax)
		VALUES ( @trx_ctrl_num, @trx_type, @sequence_id, @tax_type_code, @amt_taxable, @amt_gross, @amt_tax, @amt_final_tax ) 
	
	else
	BEGIN
		UPDATE arinptax SET 
			amt_tax = amt_tax + @amt_tax, amt_final_tax = amt_final_tax + @amt_final_tax 
		WHERE trx_ctrl_num = @trx_ctrl_num 
		AND trx_type = @trx_type 
		AND tax_type_code = @tax_type_code
		
		if @sequence_id = 1 
			UPDATE arinptax SET amt_taxable = amt_taxable + @amt_taxable , amt_gross = amt_gross + @amt_gross 
			WHERE trx_ctrl_num = @trx_ctrl_num 
			AND trx_type = @trx_type 
			AND tax_type_code = @tax_type_code
			
	END

end
if @tablename = 'apinptax' 
begin

	IF ( isnull(@p_form_id,0) != 0 )
	BEGIN
		
		IF OBJECT_ID('tempdb..#apinptaxdtl'+@p_form_id_char) IS NOT NULL 
		BEGIN
			create table #MyTempValue (tmp_amt_final_tax1 float)
			SELECT @sqlworkstring = 'insert into #MyTempValue (tmp_amt_final_tax1) 
				SELECT amt_final_tax 
				FROM #apinptaxdtl' + @p_form_id_char + ' WHERE trx_ctrl_num = '''+ @trx_ctrl_num + ''' 
				AND trx_type = '+cast(@trx_type  as varchar(20))+'
				AND tax_type_code = '''+ @tax_type_code + '''
				AND sequence_id = '+ cast(@sequence_id as varchar(20)) + 
				' AND detail_sequence_id = '+ cast(@detail_sequence_id as varchar(20))
			EXEC ( @sqlworkstring )
			
			select @tmp_amt_final_tax1 = tmp_amt_final_tax1 from #MyTempValue
			
			drop table #MyTempValue
		END
	END
	ELSE IF OBJECT_ID('tempdb..#apinptaxdtl3500') IS NOT NULL 
		SELECT @tmp_amt_final_tax1 = amt_final_tax 
		FROM #apinptaxdtl3500 WHERE trx_ctrl_num = @trx_ctrl_num 
				AND trx_type = @trx_type 
				AND tax_type_code = @tax_type_code
				AND sequence_id = @sequence_id
				AND detail_sequence_id = @detail_sequence_id
	ELSE IF OBJECT_ID('tempdb..#apinptaxdtl3560') IS NOT NULL 
		SELECT @tmp_amt_final_tax1 = amt_final_tax 
		FROM #apinptaxdtl3560 WHERE trx_ctrl_num = @trx_ctrl_num 
				AND trx_type = @trx_type 
				AND tax_type_code = @tax_type_code
				AND sequence_id = @sequence_id
				AND detail_sequence_id = @detail_sequence_id

	IF @tmp_amt_final_tax1 is not null
		SELECT @amt_final_tax = @tmp_amt_final_tax1
	
	
	if not exists(SELECT 1 FROM apinptax 
					WHERE trx_ctrl_num = @trx_ctrl_num 
					AND trx_type = @trx_type  )
		DELETE FROM  apinptaxdtl WHERE trx_ctrl_num = @trx_ctrl_num AND trx_type = @trx_type 

	if not exists(SELECT 1 FROM apinptax 
					WHERE trx_ctrl_num = @trx_ctrl_num 
					AND trx_type = @trx_type 
					AND tax_type_code = @tax_type_code )
		INSERT apinptax (trx_ctrl_num, trx_type, sequence_id, tax_type_code, amt_taxable, amt_gross, amt_tax, amt_final_tax)
		VALUES ( @trx_ctrl_num, @trx_type, @sequence_id, @tax_type_code, @amt_taxable, @amt_gross, @amt_tax, @amt_final_tax ) 
	
	else
	BEGIN
		UPDATE apinptax SET 
			amt_tax = amt_tax + @amt_tax, amt_final_tax = amt_final_tax + @amt_final_tax 
		WHERE trx_ctrl_num = @trx_ctrl_num 
		AND trx_type = @trx_type 
		AND tax_type_code = @tax_type_code

		if @sequence_id = 1 
			UPDATE apinptax SET amt_taxable = amt_taxable + @amt_taxable, amt_gross = amt_gross + @amt_gross
			WHERE trx_ctrl_num = @trx_ctrl_num 
			AND trx_type = @trx_type 
			AND tax_type_code = @tax_type_code
		
	END


	SELECT @recoverable_flag = recoverable_flag 
	FROM artxtype
	WHERE tax_type_code = @tax_type_code

	SELECT @recoverable_flag = isnull(@recoverable_flag, 0)

	INSERT INTO apinptaxdtl
	( trx_ctrl_num, sequence_id, trx_type, tax_sequence_id, detail_sequence_id, tax_type_code, 
	  amt_taxable, amt_gross, amt_tax, amt_final_tax, recoverable_flag, account_code )
	VALUES( @trx_ctrl_num, @sequence_id, @trx_type, @sequence_id, @detail_sequence_id, @tax_type_code, 
	  @amt_taxable, @amt_gross, @amt_tax, @amt_final_tax, @recoverable_flag, @account_code )
end	  
if @tablename = '#apinptaxdtl3500' 
begin		
	if not exists(SELECT 1 FROM #apinptax3500
					WHERE trx_ctrl_num = @trx_ctrl_num 
					AND trx_type = @trx_type 
					AND tax_type_code = @tax_type_code )
		INSERT #apinptax3500 (trx_ctrl_num, trx_type, sequence_id, tax_type_code, amt_taxable, amt_gross, amt_tax, amt_final_tax)
		VALUES ( @trx_ctrl_num, @trx_type, @sequence_id, @tax_type_code, @amt_taxable, @amt_gross, @amt_tax, @amt_final_tax ) 
	else
	BEGIN
		UPDATE #apinptax3500 SET 
			amt_tax = amt_tax + @amt_tax, amt_final_tax = amt_final_tax + @amt_final_tax 
		WHERE trx_ctrl_num = @trx_ctrl_num 
		AND trx_type = @trx_type 
		AND tax_type_code = @tax_type_code

		if @sequence_id = 1 
			UPDATE #apinptax3500 SET amt_taxable = amt_taxable + @amt_taxable, amt_gross = amt_gross + @amt_gross
			WHERE trx_ctrl_num = @trx_ctrl_num 
			AND trx_type = @trx_type 
			AND tax_type_code = @tax_type_code
	END
		
	SELECT @recoverable_flag = recoverable_flag 
	FROM artxtype
	WHERE tax_type_code = @tax_type_code

	SELECT @recoverable_flag = isnull(@recoverable_flag, 0)

	INSERT INTO #apinptaxdtl3500
		( 	trx_ctrl_num,	sequence_id,	trx_type,
			tax_sequence_id,	detail_sequence_id,	tax_type_code,	
			amt_taxable,	amt_gross,	amt_tax,	amt_final_tax,	
			recoverable_flag,	account_code )
	VALUES( @trx_ctrl_num, @sequence_id, @trx_type, @sequence_id, @detail_sequence_id, @tax_type_code, 
	  @amt_taxable, @amt_gross, @amt_tax, @amt_final_tax, @recoverable_flag, @account_code )
end
else if @tablename = '#apinptaxdtl3560' 
begin		
	if not exists(SELECT 1 FROM #apinptax3560
					WHERE trx_ctrl_num = @trx_ctrl_num 
					AND trx_type = @trx_type 
					AND tax_type_code = @tax_type_code )
		INSERT #apinptax3560 (trx_ctrl_num, trx_type, sequence_id, tax_type_code, amt_taxable, amt_gross, amt_tax, amt_final_tax)
		VALUES ( @trx_ctrl_num, @trx_type, @sequence_id, @tax_type_code, @amt_taxable, @amt_gross, @amt_tax, @amt_final_tax ) 
	else
	BEGIN
		UPDATE #apinptax3560 SET 
			amt_tax = amt_tax + @amt_tax, amt_final_tax = amt_final_tax + @amt_final_tax 
		WHERE trx_ctrl_num = @trx_ctrl_num 
		AND trx_type = @trx_type 
		AND tax_type_code = @tax_type_code
		
		if @sequence_id = 1
			UPDATE #apinptax3560 SET amt_taxable = amt_taxable + @amt_taxable, amt_gross = amt_gross + @amt_gross
			WHERE trx_ctrl_num = @trx_ctrl_num 
			AND trx_type = @trx_type 
			AND tax_type_code = @tax_type_code
					
	END

	SELECT @recoverable_flag = recoverable_flag 
	FROM artxtype
	WHERE tax_type_code = @tax_type_code

	SELECT @recoverable_flag = isnull(@recoverable_flag, 0)
	
	INSERT INTO #apinptaxdtl3560
		( 	trx_ctrl_num,	sequence_id,	trx_type,
			tax_sequence_id,	detail_sequence_id,	tax_type_code,	
			amt_taxable,	amt_gross,	amt_tax,	amt_final_tax,	
			recoverable_flag,	account_code )
	VALUES( @trx_ctrl_num, @sequence_id, @trx_type, @sequence_id, @detail_sequence_id, @tax_type_code, 
	  @amt_taxable, @amt_gross, @amt_tax, @amt_final_tax, @recoverable_flag, @account_code )
end
else if @tablename = '#apinptaxdtl' + @p_form_id_char
begin		

	SELECT @sqlworkstring = '	if not exists(SELECT 1 FROM #apinptax' + @p_form_id_char + '
					WHERE trx_ctrl_num = '''+@trx_ctrl_num+''' 
					AND trx_type = '+cast(@trx_type  as varchar(20))+' 
					AND tax_type_code = '''+@tax_type_code+''' )
		INSERT #apinptax' + @p_form_id_char + '
		(trx_ctrl_num, trx_type, sequence_id, tax_type_code, amt_taxable, amt_gross, amt_tax, amt_final_tax)
		VALUES ( '''+@trx_ctrl_num+''', '+cast(@trx_type  as varchar(20))+', '+cast(@sequence_id as varchar(20))+', 
		'''+@tax_type_code+''', '+cast(@amt_taxable as varchar(20))+', '+cast(@amt_gross as varchar(20))+', '
		+cast(@amt_tax as varchar(20))+', '+cast(@amt_final_tax as varchar(20))+' ) 
	else
	BEGIN
		UPDATE #apinptax' + @p_form_id_char + 
		' SET '+
		case @sequence_id when 1 then 'amt_taxable = amt_taxable + '+cast(@amt_taxable as varchar(20))+', '
									+' amt_gross = amt_gross + '+cast(@amt_gross as varchar(20))+', ' 
				else '' end +
		'amt_tax = amt_tax + '+cast(@amt_tax as varchar(20))+', 
		amt_final_tax = amt_final_tax + '+cast(@amt_final_tax as varchar(20))+' 
		WHERE trx_ctrl_num = '''+@trx_ctrl_num+''' 
		AND trx_type = '+cast(@trx_type  as varchar(20))+'
		AND tax_type_code = '''+@tax_type_code+'''
	END
	'
	EXEC(@sqlworkstring)
	
	SELECT @recoverable_flag = recoverable_flag 
	FROM artxtype
	WHERE tax_type_code = @tax_type_code

	SELECT @recoverable_flag = isnull(@recoverable_flag, 0)
	
	SELECT @sqlworkstring ='INSERT INTO #apinptaxdtl' + @p_form_id_char + '
		( 	trx_ctrl_num,	sequence_id,	trx_type,
			tax_sequence_id,	detail_sequence_id,	tax_type_code,	
			amt_taxable,	amt_gross,	amt_tax,	amt_final_tax,	
			recoverable_flag,	account_code )
	VALUES( '''+@trx_ctrl_num+''', '+cast(@sequence_id as varchar(20))+', '+cast(@trx_type  as varchar(20))+', 
	  '+cast(@sequence_id as varchar(20))+', '+cast(@detail_sequence_id as varchar(20))+', '''+@tax_type_code+''', 
	  '+cast(@amt_taxable as varchar(20))+', '+cast(@amt_gross as varchar(20))+', '+cast(@amt_tax as varchar(20))+',
	  '+cast(@amt_final_tax as varchar(20))+', '+cast(@recoverable_flag as varchar(20))+', '''+@account_code+''' )
	  '
	EXEC ( @sqlworkstring )
end
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[gltc_addinptax_sp] TO [public]
GO
