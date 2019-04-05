//Returns a int64 from a string. GDScript int(string) function returns int32, not int64.
//To do: add error handling 

using Godot;
using System;

public class BigMath : Node
{
    
	//string to Int64
	public static long StrToInt64(string s)
    {
	
	long result = Int64.Parse(s);
	return result;
	}
	
	/*
	
	Used in testing, ignore
	
	//float to Int64 - doesn't work properly
	public static long FloatToInt64(double f)
    {
	
	long result = Convert.ToInt64(f * 1000000000000);
	return result;
	}
	
	//Int64 to string
	public static string Int64ToString(long i)
    {
	
	//string result = Convert.ToString(i);
	string result = Convert.ToString(i, 10);
	return result;
	}
	
	//Float to string
	public static string FloatToString(float f)
    {
	
	//string result = Convert.ToString(f);
	string result = f.ToString();
	return result;
	}
	
	//convert int <=100000 to Dero Int64
	public static long IntToDeroInt64(int i)
    {
	//convert to long
	long result = i * 10000000;
	return result;
	}
	
	//Float to raw dero as string
	//public static string StrToDero(float f)
    //{
	
	//string result = Convert.ToString(f*1000000000000);
	//return result;
	//}
	*/
}
