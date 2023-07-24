// This file contains your Data Connector logic
[Version = "1.0.0"]
section BuildingConnected;

clientId = Text.FromBinary(Extension.Contents("clientId"));
clientSecret = Text.FromBinary(Extension.Contents("clientSecret"));
redirectUrl = "https://oauth.powerbi.com/views/oauthredirect.html";

windowHeight = 1000;
windowWidth = 1200;

[DataSource.Kind="BuildingConnected", Publish="BuildingConnected.Publish"]
shared BuildingConnected.Contents = () =>
    let 
        Source = BuildingConnected.Me()
    in
        Source;

[DataSource.Kind="BuildingConnected"]
shared BuildingConnected.Users = () =>
    let
        Source = Json.Document(Web.Contents("https://developer.api.autodesk.com/construction/buildingconnected/v2/users"))
    in
        Source;

[DataSource.Kind="BuildingConnected"]
shared BuildingConnected.Me = () =>
    let
        Source = Json.Document(Web.Contents("https://developer.api.autodesk.com/construction/buildingconnected/v2/users/me"))
    in
        Source;

[DataSource.Kind="BuildingConnected"]
shared BuildingConnected.MyOffices = () =>
    let
        Source = BuildingConnected.Me(),
        offices = Source[offices],
        #"Converted to Table" = Table.FromList(offices, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        #"Expanded Column" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"id", "name", "address"}, {"Column1.id", "Column1.name", "Column1.address"}),
        #"Renamed Columns" = Table.RenameColumns(#"Expanded Column" ,{{"Column1.id", "ID"}, {"Column1.name", "Office"}, {"Column1.address", "Address"}})
    in
        #"Renamed Columns" ;

[DataSource.Kind="BuildingConnected"]
shared BuildingConnected.RawOpportunities = () =>
    let
        Source = List.Generate(()=>[response=BuildingConnected.OpportunityPage()],
                each [response][pagination][nextUrl] <> null,
                each [response = BuildingConnected.OpportunityPage([response][pagination][nextUrl])],
                each [response][results]),
        #"Converted to Table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error)
    in
        #"Converted to Table";

[DataSource.Kind="BuildingConnected"]
shared BuildingConnected.OpportunityPage = (optional nextURL as text) =>
    let
        nextURL = if nextURL = null 
            then "https://developer.api.autodesk.com/construction/buildingconnected/v2/opportunities"
            else "https://developer.api.autodesk.com" & nextURL,
        Source = Json.Document(Web.Contents(nextURL))
    in
        Source;



// Data Source Kind description
BuildingConnected = [
    Authentication = [
        OAuth = [
            StartLogin = StartLogin,
            FinishLogin = FinishLogin,
            Refresh = Refresh
        ]
    ]
];


//OAUTH2 Flow Definitions
StartLogin = (resourceUrl, state, display) =>
        let
            AuthorizeUrl = "https://developer.api.autodesk.com/authentication/v2/authorize?" & Uri.BuildQueryString([
                response_type="code",
                client_id = clientId,
                scope = "data:read",
                redirect_uri = redirectUrl])
        in
            [
                LoginUri = AuthorizeUrl,
                CallbackUri = redirectUrl,
                WindowHeight = windowHeight,
                WindowWidth = windowWidth,
                Context = null
            ];

FinishLogin = (context, callbackUri, state) =>
    let
        Parts = Uri.Parts(callbackUri)[Query]
    in
        TokenMethod(Parts[code]);

TokenMethod = (code) =>
    let
        Response = Web.Contents("https://developer.api.autodesk.com/authentication/v2/token", [
            Content = Text.ToBinary(Uri.BuildQueryString([     
                grant_type= "authorization_code",
                code = code,
                redirect_uri = redirectUrl])),
            Headers=[
                #"Content-type" = "application/x-www-form-urlencoded",
                #"Accept" = "application/json",
                #"Accept-Encoding"="gzip",
                #"Connection"="keep-alive",
                #"Authorization" = "Basic " & Binary.ToText(Text.ToBinary(clientId & ":" & clientSecret,BinaryEncoding.Base64),BinaryEncoding.Base64)]]),
        Parts = Json.Document(Response)
    in
        Parts;

Refresh = (resourceUrl, refresh_token)  => RefreshTokenMethod(refresh_token);

RefreshTokenMethod = (refreshToken) =>
    let
        Response = Web.Contents("https://developer.api.autodesk.com/authentication/v2/token", [
            Content = Text.ToBinary(Uri.BuildQueryString([     
                grant_type= "refresh_token",
                refresh_token = refreshToken,
                redirect_uri = redirectUrl])),
            Headers=[
                #"Content-type" = "application/x-www-form-urlencoded",
                #"Accept" = "application/json",
                #"Accept-Encoding"="gzip",
                #"Connection"="keep-alive",
                #"Authorization" = "Basic " & Binary.ToText(Text.ToBinary(clientId & ":" & clientSecret, BinaryEncoding.Base64),BinaryEncoding.Base64)]]
        ),
        Parts = Json.Document(Response)
    in
        Parts;


// Data Source UI publishing description
BuildingConnected.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = BuildingConnected.Icons,
    SourceTypeImage = BuildingConnected.Icons
];

BuildingConnected.Icons = [
    Icon16 = { Extension.Contents("BuildingConnected16.png"), Extension.Contents("BuildingConnected20.png"), Extension.Contents("BuildingConnected24.png"), Extension.Contents("BuildingConnected32.png") },
    Icon32 = { Extension.Contents("BuildingConnected32.png"), Extension.Contents("BuildingConnected40.png"), Extension.Contents("BuildingConnected48.png"), Extension.Contents("BuildingConnected64.png") }
];
