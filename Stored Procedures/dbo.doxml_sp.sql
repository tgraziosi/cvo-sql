SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


/*                                                      
               Confidential Information                 
    Limited Distribution of Authorized Persons Only     
    Created 2005 and Protected as Unpublished Work      
          Under the U.S. Copyright Act of 1976          
 Copyright (c) 2005 Epicor Software Corporation, 2005   
                  All Rights Reserved                   
*/

CREATE PROCEDURE [dbo].[doxml_sp] @pathout VARCHAR(8000), @pathtemp VARCHAR(8000), @nametemp VARCHAR(50), @tag VARCHAR(20), @type int
AS
BEGIN
	DECLARE @cmd VARCHAR(8000), @text1 VARCHAR(8000), @text2 VARCHAR(8000), @text3 VARCHAR(200), @text4 VARCHAR(200), 
	@id VARCHAR(40), @ind INT, @pos INT, @result INT, @s VARCHAR(2), @flg int, @tag2 VARCHAR(20)
	DECLARE @company smallint,@compline int

	CREATE TABLE ##tempXML ( line VARCHAR(8000), val INT ) 
	CREATE TABLE #TXML ( noline INT NOT NULL IDENTITY(1,1), line VARCHAR(8000) ) 
	
	SET @cmd = 'type "' + @pathtemp + '\' + @nametemp + '.xml"' 
	SET @text2 = ''
	SET @id = NEWID( )
	SET @flg = 0
	SET @text3 = ''
	SET @text4 = ''

	EXEC @result = master..xp_cmdshell @cmd, NO_OUTPUT

	IF (@result = 0)
		INSERT INTO #TXML EXEC master..xp_cmdshell @cmd
	ELSE
	BEGIN
		DROP TABLE ##tempXML
		DROP TABLE #TXML	
		RETURN
	END

	SET @ind = ( 	SELECT noline
			FROM #TXML 
			WHERE CHARINDEX( '</xmlDoc>', line ) > 0 )
	SET @pos = ( 	SELECT CHARINDEX( '</xmlDoc>', line )
			FROM #TXML
			WHERE noline = @ind )
	SET @text1 = ( 	SELECT SUBSTRING( line, 1, @pos - 1 )
			FROM #TXML 
			WHERE noline = @ind ) 


	IF( ( SELECT CHARINDEX( '<xmlDoc>', @text1 ) ) > 0 )
	BEGIN
		SET @text2 = '
'			   + '	  ' + (	SELECT SUBSTRING( line, @pos, 8000 )FROM #TXML WHERE noline = @ind ) 

		UPDATE #TXML SET line = @text1 WHERE noline = @ind			
		SET @ind = @ind + 1
	END

	/*Begin. EPR: 050282*/
	IF @type = 1 OR @type = 4 
	BEGIN
		SELECT @company = company_id
		FROM  glco

		UPDATE #TXML SET line = '	  <companyCode>' + CAST(@company AS VARCHAR(50))  + '</companyCode>'
		WHERE CHARINDEX( '<companyCode>', line) > 0
		
	END
	IF @type =  2
		BEGIN
			UPDATE #TXML SET line = '	  <Supplier>SUPPJOB</Supplier>'
			WHERE CHARINDEX( '<Supplier>', line) > 0

			UPDATE #TXML SET line = '	  <Catalog>CATAJOB</Catalog>'
			WHERE CHARINDEX( '<Catalog>', line) > 0
	END

	/*End. EPR: 050282*/

	SET @pos = 4
	SET @text1 = @tag

	SET ROWCOUNT 75000
	
	IF( @type < 4 )
		UPDATE epintegrationrecs SET proc_flag = 1 WHERE type = @type
	ELSE IF( @type < 7 )
	BEGIN
		UPDATE epintegrationrecs SET proc_flag = 1 WHERE type BETWEEN 4 AND 6 
		SET @flg = 1
	END

	WHILE( @pos != 0 )
	BEGIN	
		IF( @type = 4 )
			SET @tag = 'account'
		ELSE IF ( @type = 5 )
		BEGIN
			SET @tag = 'reftype'
			SET @tag2 = 'mask'
		END
		ELSE IF ( @type = 6 )
		BEGIN
			SET @tag = 'refcode'
			SET @tag2 = 'reftype'
		END

		IF( ( SELECT COUNT(id_code) FROM epintegrationrecs WHERE type = @type ) > 0 )
		BEGIN				
			IF( @type BETWEEN 4 AND 6 )
				SET @s = '  '
			ELSE
				SET @s = ''

			IF( @type IN ( 5, 6 ) )
			BEGIN
				SET @text3 = '                  <' + @tag2 + '>'
				SET @text4 = '</' + @tag2 + '>
'
			END

			INSERT INTO ##tempXML SELECT  @s +'              <' + @tag + '>
'       	        	                    + @s +'                <id>'+ dbo.ep_replace_characters(id_code) +'</id>
'               	        	            + @text3 + CASE @type WHEN 6 THEN  dbo.ep_replace_characters(mask) ELSE mask END + @text4
						    + @s +'                <status>'+ action+'</status>
'						    + @s +'              </' + @tag + '>', @pos FROM epintegrationrecs WHERE type = @type AND proc_flag = 1
			SET ROWCOUNT 0
		END

		IF( @flg = 1 )
		BEGIN
			INSERT INTO ##tempXML SELECT '              <' + @tag + 's>', @pos - 1
			INSERT INTO ##tempXML SELECT '              </' + @tag + 's>', @pos + 1				
		END

		IF( @type > 3 )
		BEGIN
			SET @type = @type + 1		
			SET @pos = @pos + 3		
		END
		IF ( @type < 4 OR @type = 7 )
			SET @pos = 0
	END

	IF( @type BETWEEN 1 AND 3 )
		SET @s = 's'
	ELSE
		SET @s = ''

	SET @tag = @text1

	INSERT INTO ##tempXML SELECT line, 1 FROM #TXML WHERE noline < @ind
	INSERT INTO ##tempXML SELECT '            <' + @tag + @s + '>', 2 
	INSERT INTO ##tempXML SELECT '            </' + @tag + @s + '>' + @text2, 12	
	INSERT INTO ##tempXML SELECT line, 13 FROM #TXML WHERE noline >= @ind

	SET @cmd = 'bcp "SELECT line FROM ##tempXML ORDER BY val" queryout "'+ @pathout + '\' + @id +'.xml"  -n /c /T /S' + @@SERVERNAME 	

	EXEC @result = master..xp_cmdshell @cmd, NO_OUTPUT

	IF (@result != 0)
		UPDATE epintegrationrecs SET proc_flag = 0

	DELETE epintegrationrecs WHERE proc_flag = 1 
	
	DROP TABLE ##tempXML
	DROP TABLE #TXML	
END

GO
GRANT EXECUTE ON  [dbo].[doxml_sp] TO [public]
GO
