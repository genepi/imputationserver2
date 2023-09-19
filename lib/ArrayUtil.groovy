class ArrayUtil {

    public static String sort(Collection data) {
       def dataArray = data as String[]
       def dataSorted = dataArray.sort(false) { it }
       def dataJoined = dataSorted.join(" ")
       return dataJoined;
    }
}