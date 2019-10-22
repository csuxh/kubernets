namespace java com.xej.thrift.demo
namespace py thrift.demo
namespace go com.xej.thrift.demo

service DemoService{
    void sayHello(1:string name);
}
