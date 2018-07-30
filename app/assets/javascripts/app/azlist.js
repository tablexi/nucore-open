
var oldText = "All Facilities"

function removeExtraClasses(classlist) {
    if (classlist.includes("all")) return "all"
    else if(classlist.includes("recent")) return "recent"
    return "js--azlist" + classlist.replace(" ", "").split("js--azlist")[1]
}

$(document).ready(function () {
    oldText = $(".allHeader").text()
})
$(document).on("click", ".js--az_listing", function () {
    $(".js--facility_listing").hide();
    var category = removeExtraClasses( $(this).attr("class") )
    console.log(category)
    if (category === "recent") $(".recent").show()
    else if (category === "all") {
        $(".allHeader").text(oldText)
        $(".js--facility_listing").show()
    }
    else {
        $("." + category).show()
        $(".allHeader").show()
        $(".allHeader").text($(this).text())
    }
});
