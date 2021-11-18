function JsonData = exportJson()
%TOJSON loads and converts loaded namespaces to json strings
%   returns containers.map of namespace names.

% Get the actual location of the matnwb directory.
namespaceList = dir(misc.getNamespaceDir());
isFileMask = ~[namespaceList.isdir];
namespaceFiles = namespaceList(isFileMask);
namespaceNames = {namespaceFiles.name};
for iFile = 1:length(namespaceNames)
    [~, namespaceNames{iFile}, ~] = fileparts(namespaceNames{iFile});
end

Caches = spec.loadCache(namespaceNames{:});
JsonData = struct(...
    'name', namespaceNames,...
    'version', repmat({''}, size(Caches)),...
    'json', repmat({containers.Map.empty}, size(Caches)));
for iCache = 1:length(Caches)
    Cache = Caches(iCache);
    keepRelevantNamespace(Cache);
    stripNamespaceFileExt(Cache.namespace);
    JsonMap = containers.Map({'namespace'}, {jsonencode(Cache.namespace, 'ConvertInfAndNaN', true)});
    for iScheme = 1:length(Cache.filenames)
        filename = Cache.filenames{iScheme};
        jsonencode(Cache.schema(filename));
        JsonMap(filename) = jsonencode(Cache.schema(filename), 'ConvertInfAndNaN', true);
    end
    
    JsonData(iCache).version = Cache.version;
    JsonData(iCache).json = JsonMap;
end
end
function keepRelevantNamespace(Cache)
    Namespaces = Cache.namespace('namespaces');
    ns = 1;
    while ns <= length(Namespaces)
        Namespace = Namespaces{ns};
        if ~strcmp(Cache.name, Namespace('name'))
            Namespaces(ns) = [];
        end
        ns = ns+1;
    end
    Cache.namespace('namespaces') = Namespaces;
end
function NamespaceRoot = stripNamespaceFileExt(NamespaceRoot)
Namespaces = NamespaceRoot('namespaces');
for ns = 1:length(Namespaces)
    Namespace = Namespaces{ns};
    Schema = Namespace('schema');
    for iScheme = 1:length(Schema)
        Scheme = Schema{iScheme};
        if ~Scheme.isKey('source')
            continue;
        end
        source = Scheme('source');

        if endsWith(source, '.yaml')
            [~, Scheme('source'), ~] = fileparts(source);
        end
    end
end
end