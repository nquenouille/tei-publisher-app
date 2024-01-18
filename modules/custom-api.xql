xquery version "3.1";

module namespace api="http://teipublisher.com/api/custom";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace dapi="http://teipublisher.com/api/documents" at "lib/api/document.xql";
import module namespace errors = "http://e-editiones.org/roaster/errors";
import module namespace rutil="http://e-editiones.org/roaster/util";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xql";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "../../navigation.xql";
import module namespace http = "http://expath.org/ns/http-client";
import module namespace router="http://e-editiones.org/roaster";


declare function api:lookup($name as xs:string, $arity as xs:integer) {
    try {
        function-lookup(xs:QName($name), $arity)
    } catch * {
        ()
    }
};

(: Get status of availability of the document :)
declare function api:status-metadata($request as map(*)) {
    let $doc := xmldb:decode($request?parameters?path)
    let $xml := config:get-document($doc)
    return
        if (exists($xml)) then
            let $config := tpu:parse-pi(root($xml), ())
            let $attr := root($xml)//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability/@status
            return map {"content": data($attr)}
        else
            error($errors:NOT_FOUND, "Document " || $doc || " not found")
};

(:~
 : Merge and save the status passed in the request body.
 :)
declare function api:status-save($request as map(*)) {
    let $body := $request?body
    let $header := $request?head
    let $path := xmldb:decode($request?parameters?path)
    let $srcDoc := config:get-document($path)
    let $stat := $request?parameters?status
    let $hasAccess := sm:has-access(document-uri(root($srcDoc)), "rw-")
    return
        if (not($hasAccess) and request:get-method() = 'PUT') then
            error($errors:FORBIDDEN, "Not allowed to write to " || $path)
        else if ($srcDoc) then
            let $doc := util:expand($srcDoc/*, 'add-exist-id=all')
            let $attr := $srcDoc//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability
            let $status := $srcDoc//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability/@status
            let $docMerge := 
                if (exists($attr)) then 
                    update value $status with $stat
                else 
                    update insert (<tei:availability status="status.new"><tei:licence target="https://creativecommons.org/licenses/by-nc-sa/4.0/">CC BY-NC-SA 4.0</tei:licence></tei:availability>) into $srcDoc//tei:teiHeader/tei:fileDesc/tei:publicationStmt
(:            let $stored :=:)
(:                if (request:get-method() = 'PUT') then :)
(:                    xmldb:store(util:collection-name($srcDoc), util:document-name($srcDoc), $srcDoc):)
(:                else:)
(:                    ():)
            return map {
                    "content": $srcDoc}
        else
            error($errors:NOT_FOUND, "Document " || $path || " not found")
};


(: Get documents that are finished :)
declare function api:get-doc($request as map(*)) {
    let $doc := xmldb:decode($request?parameters?id)
    let $srcDoc := config:get-document($doc)
    return
        if ($doc) then
            let $path := xmldb:encode-uri($config:data-root || "/" || $doc)
            let $filename := replace($doc, "^.*/([^/]+)$", "$1")
            let $mime := ($request?parameters?type, xmldb:get-mime-type($path))[1]
            let $src := util:expand($srcDoc/*, 'add-exist-id=all')
            let $attr := $src//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability[@status="status.final"]
            return
                if (util:binary-doc-available($path) and $attr) then
                    response:stream-binary(util:binary-doc($path), $mime, $filename)
                else if (doc-available($path) and $attr) then
                    router:response(200, $mime, doc($path))
                else
                    error($errors:NOT_FOUND, "Document " || $doc || " not found")
        else
            error($errors:BAD_REQUEST, "No document specified")
};

(: Check which documents have status='status.final' and show name, description and status :)

declare function api:list-finished-documents($request as map(*)) {
    array {
        for $html in collection($config:app-root || "/data/annotate")/*
        let $description := $html//tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/string()
        let $status := $html//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability/@status/string()
        let $path := $config:app-root || "/data/annotate/" || util:document-name($html)
        return
            if($status = "status.final") then
            map {
                "name": util:document-name($html),
                "path": $path,
                "title": $description,
                "status": $status
            }
            else
            ()
    }
};

(: Get documents that are finished and store them into the edition's app. CAVEAT: If name of the edition's app changes, change it here, too! :)
declare function api:save-doc($request as map(*)) {
    let $doc := xmldb:decode($request?parameters?id)
    let $srcDoc := config:get-document($doc)
    return
        if ($doc) then
            let $path := xmldb:encode-uri($config:data-root || "/" || $doc)
            let $storepath := xmldb:encode-uri("../db/apps/BachLetters/data/")
            let $filename := replace($doc, "^.*/([^/]+)$", "$1")
            let $mime := ($request?parameters?type, xmldb:get-mime-type($path))[1]
            let $src := util:expand($srcDoc/*, 'add-exist-id=all')
            let $attr := $src//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability[@status="status.final"]
            
            let $stored := xmldb:store($storepath, $request?parameters?id || ".xml", $srcDoc, "text/xml")
            return
                if (util:binary-doc-available($path) and $attr) then
                    response:stream-binary(util:binary-doc($path), $mime, $filename)
                else if (doc-available($path) and $attr) then
                    router:response(200, $mime, doc($path))
                else
                    error($errors:NOT_FOUND, "Document " || $doc || " not found")
        else
            error($errors:BAD_REQUEST, "No document specified")
};