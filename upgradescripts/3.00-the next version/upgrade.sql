﻿--upgrade scripts from nopCommerce 3.00 to 3.10

--new locale resources
declare @resources xml
--a resource will be delete if its value is empty
set @resources='
<Language>
  <LocaleResource Name="">
    <Value></Value>
  </LocaleResource>
</Language>
'

CREATE TABLE #LocaleStringResourceTmp
	(
		[ResourceName] [nvarchar](200) NOT NULL,
		[ResourceValue] [nvarchar](max) NOT NULL
	)

INSERT INTO #LocaleStringResourceTmp (ResourceName, ResourceValue)
SELECT	nref.value('@Name', 'nvarchar(200)'), nref.value('Value[1]', 'nvarchar(MAX)')
FROM	@resources.nodes('//Language/LocaleResource') AS R(nref)

--do it for each existing language
DECLARE @ExistingLanguageID int
DECLARE cur_existinglanguage CURSOR FOR
SELECT [ID]
FROM [Language]
OPEN cur_existinglanguage
FETCH NEXT FROM cur_existinglanguage INTO @ExistingLanguageID
WHILE @@FETCH_STATUS = 0
BEGIN
	DECLARE @ResourceName nvarchar(200)
	DECLARE @ResourceValue nvarchar(MAX)
	DECLARE cur_localeresource CURSOR FOR
	SELECT ResourceName, ResourceValue
	FROM #LocaleStringResourceTmp
	OPEN cur_localeresource
	FETCH NEXT FROM cur_localeresource INTO @ResourceName, @ResourceValue
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF (EXISTS (SELECT 1 FROM [LocaleStringResource] WHERE LanguageID=@ExistingLanguageID AND ResourceName=@ResourceName))
		BEGIN
			UPDATE [LocaleStringResource]
			SET [ResourceValue]=@ResourceValue
			WHERE LanguageID=@ExistingLanguageID AND ResourceName=@ResourceName
		END
		ELSE 
		BEGIN
			INSERT INTO [LocaleStringResource]
			(
				[LanguageId],
				[ResourceName],
				[ResourceValue]
			)
			VALUES
			(
				@ExistingLanguageID,
				@ResourceName,
				@ResourceValue
			)
		END
		
		IF (@ResourceValue is null or @ResourceValue = '')
		BEGIN
			DELETE [LocaleStringResource]
			WHERE LanguageID=@ExistingLanguageID AND ResourceName=@ResourceName
		END
		
		FETCH NEXT FROM cur_localeresource INTO @ResourceName, @ResourceValue
	END
	CLOSE cur_localeresource
	DEALLOCATE cur_localeresource


	--fetch next language identifier
	FETCH NEXT FROM cur_existinglanguage INTO @ExistingLanguageID
END
CLOSE cur_existinglanguage
DEALLOCATE cur_existinglanguage

DROP TABLE #LocaleStringResourceTmp
GO

--more indexes
IF NOT EXISTS (SELECT 1 from sys.indexes WHERE [NAME]=N'IX_Category_LimitedToStores' and object_id=object_id(N'[Category]'))
BEGIN
	CREATE NONCLUSTERED INDEX [IX_Category_LimitedToStores] ON [Category] ([LimitedToStores] ASC)
END
GO

IF NOT EXISTS (SELECT 1 from sys.indexes WHERE [NAME]=N'IX_Manufacturer_LimitedToStores' and object_id=object_id(N'[Manufacturer]'))
BEGIN
	CREATE NONCLUSTERED INDEX [IX_Manufacturer_LimitedToStores] ON [Manufacturer] ([LimitedToStores] ASC)
END
GO

IF NOT EXISTS (SELECT 1 from sys.indexes WHERE [NAME]=N'IX_Product_LimitedToStores' and object_id=object_id(N'[Product]'))
BEGIN
	CREATE NONCLUSTERED INDEX [IX_Product_LimitedToStores] ON [Product] ([LimitedToStores] ASC)
END
GO




IF NOT EXISTS (SELECT 1 from sys.indexes WHERE [NAME]=N'IX_Category_SubjectToAcl' and object_id=object_id(N'[Category]'))
BEGIN
	CREATE NONCLUSTERED INDEX [IX_Category_SubjectToAcl] ON [Category] ([SubjectToAcl] ASC)
END
GO

IF NOT EXISTS (SELECT 1 from sys.indexes WHERE [NAME]=N'IX_Manufacturer_SubjectToAcl' and object_id=object_id(N'[Manufacturer]'))
BEGIN
	CREATE NONCLUSTERED INDEX [IX_Manufacturer_SubjectToAcl] ON [Manufacturer] ([SubjectToAcl] ASC)
END
GO

IF NOT EXISTS (SELECT 1 from sys.indexes WHERE [NAME]=N'IX_Product_SubjectToAcl' and object_id=object_id(N'[Product]'))
BEGIN
	CREATE NONCLUSTERED INDEX [IX_Product_SubjectToAcl] ON [Product] ([SubjectToAcl] ASC)
END
GO