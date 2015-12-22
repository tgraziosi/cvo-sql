SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
--  Change so that an entire set of presentation properties can be deleted with a single call.

CREATE PROCEDURE [dbo].[fs_registry]
	(
	@registry_key	VARCHAR(255),
	@registry_mode	CHAR(1)	= 'G',
	@registry_type	CHAR(1)	= NULL		OUT,	
	@registry_data	VARCHAR(255) = ''	OUT,	
	@wrap_call      int = 0				-- mls 7/9/01 SCR 27161
	)

AS
BEGIN


























DECLARE	@registry_id	INT,
	@registry_name	VARCHAR(32),

	@length		INT,
	@index		INT,
        @lowerLim       INT,
        @upperLim       INT


SELECT	@registry_id = NULL

IF @registry_mode = 'X'
BEGIN

-- Delete all the presentation properties entries under the requested name.
SELECT @lowerLim = R.registry_id 
       FROM dbo.registry R
       WHERE R.parent_id = 1 AND
             R.registry_name = @registry_key
IF @@rowcount = 0
	BEGIN
	
	RETURN

	END
SELECT @upperLim = IsNull(MIN(R.registry_id),999999)
       FROM dbo.registry R
       WHERE R.parent_id = 1 AND
             R.registry_name <> @registry_key AND
             R.registry_id > @lowerLim

DELETE dbo.registry
       WHERE registry_id >= @lowerLim AND
             registry_id < @upperLim
RETURN 1

END

WHILE @registry_key <> ''
	BEGIN
	
	SELECT	@index = CharIndex('/',@registry_key)

	
	IF @index > 0
		BEGIN
		
		IF @index > 1
			
			SELECT @registry_name = SubString(@registry_key,1,@index - 1)
		ELSE
			
			SELECT @registry_name = NULL

		
		SELECT @registry_key = SubString(@registry_key,@index + 1,255)
		END
	ELSE
		BEGIN
		
		SELECT @registry_name = @registry_key

		
		SELECT @registry_key = ''
		END

	
	IF @registry_name IS NOT NULL
		BEGIN
		
		IF @registry_id IS NULL
			SELECT	@registry_id=R.registry_id
			FROM	dbo.registry R
			WHERE	R.parent_id IS NULL
			AND	R.registry_name=@registry_name
		ELSE
			SELECT	@registry_id=R.registry_id
			FROM	dbo.registry R
			WHERE	R.parent_id = @registry_id
			AND	R.registry_name=@registry_name

		
		IF @@rowcount = 0
			BEGIN
			
			IF @registry_mode IN ('C','A')
				BEGIN
				
				IF @registry_key = ''
					INSERT INTO dbo.registry(parent_id,registry_name,registry_type,registry_data)
					VALUES(@registry_id,@registry_name,@registry_type,@registry_data)
				ELSE
					INSERT INTO dbo.registry(parent_id,registry_name,registry_type,registry_data)
					VALUES(@registry_id,@registry_name,'D','')

				SELECT @registry_id=@@identity
				END
			ELSE
				BEGIN
				if @wrap_call = 0				-- mls 7/9/01 SCR 27161
				RaisError 69540 'Registry key not found'
				RETURN 69540					-- mls 7/9/01 SCR 27161
				END
			END
		END
	END


IF @registry_id IS NULL
	BEGIN
	if @wrap_call = 0				-- mls 7/9/01 SCR 27161
	RaisError 69540 'Registry key not found'
	RETURN 69540                                    -- mls 7/9/01 SCR 27161
	END


IF @registry_mode IN ('G','A')
	SELECT	@registry_data=R.registry_data
	FROM	dbo.registry R
	WHERE	R.registry_id = @registry_id
IF @registry_mode IN ('S','C')
	UPDATE	dbo.registry
	SET	registry_data=@registry_data
	WHERE	registry_id = @registry_id
IF @registry_mode = 'D'
	DELETE	dbo.registry
	WHERE	registry_id = @registry_id

RETURN 1									-- mls 7/9/01 SCR 27161
END
GO
GRANT EXECUTE ON  [dbo].[fs_registry] TO [public]
GO
