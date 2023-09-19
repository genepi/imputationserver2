class Manipulations {

    public static String sortValues(Collection data) {
       def dataArray = data as String[]
       def dataSorted = dataArray.sort(false) { it.tokenize('_')[2] as Integer }
       def dataJoined = dataSorted.join(" ")
       return dataJoined;
    }
}