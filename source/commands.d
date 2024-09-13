import std;
import interpreter;
int add(ref Machine machine, real[] params) {
    handleRegisters(machine, params, 2);
    machine.registers.a = cast(int)(params[0] + params[1]);
    handleFlags(machine, machine.registers.a);
    return 2;
}

int sub(ref Machine machine, real[] params) {
    handleRegisters(machine, params, 2);
    machine.registers.a = cast(int)(params[0] - params[1]);
    handleFlags(machine, machine.registers.a);
    return 2;
}

int mul(ref Machine machine, real[] params) {
    handleRegisters(machine, params, 2);
    machine.registers.a = cast(int)(params[0] * params[1]);
    handleFlags(machine, machine.registers.a);
    return 2;
}

int div(ref Machine machine, real[] params) {
    handleRegisters(machine, params, 2);
    machine.registers.f = cast(float)(params[0] / params[1]);
    handleFlags(machine, machine.registers.f);
    return 2;
}

int addf(ref Machine machine, real[] params) {
    handleRegisters(machine, params, 2);
    machine.registers.f = cast(float)params[0] + cast(float)params[1];
    handleFlags(machine, machine.registers.f);
    return 2;
}

int subf(ref Machine machine, real[] params) {
    handleRegisters(machine, params, 2);
    machine.registers.f = cast(float)params[0] - cast(float)params[1];
    handleFlags(machine, machine.registers.f);
    return 2;
}

int mulf(ref Machine machine, real[] params) {
    handleRegisters(machine, params, 2);
    machine.registers.f = cast(float)params[0] * cast(float)params[1];
    handleFlags(machine, machine.registers.f);
    return 2;
}

int and(ref Machine machine, real[] params) {
    handleRegisters(machine, params, 2);
    machine.registers.a = cast(int)(cast(int)params[0] & cast(int)params[1]);
    handleFlags(machine, machine.registers.a);
    return 2;
}

int not(ref Machine machine, real[] params) {
    handleRegisters(machine, params, 1);
    machine.registers.a = cast(int)(~cast(int)params[0]);
    handleFlags(machine, machine.registers.a);
    return 1;
}

int or(ref Machine machine, real[] params) {
    handleRegisters(machine, params, 2);
    machine.registers.a = cast(int)(cast(int)params[0] | cast(int)params[1]);
    handleFlags(machine, machine.registers.a);
    return 2;
}

int xor(ref Machine machine, real[] params) {
    handleRegisters(machine, params, 2);
    machine.registers.a = cast(int)(cast(int)params[0] ^ cast(int)params[1]);
    handleFlags(machine, machine.registers.a);
    return 2;
}

int cp(ref Machine machine, real[] params) {
    handleRegisters(machine, params, 1);
    for (int j = 0; j < 9; j++) {
            if (params[1] == (real.max - j)) {
                if(j!=5)setRegister(machine, j,params[1]);
            }
        }
    return 0;
}
int jmp(ref Machine machine, real[] params) {
    handleRegisters(machine, params, 1);
    machine.ip = (cast(int)params[0])-1;
    return 0;
}
int jz(ref Machine machine, real[] params) {
    handleRegisters(machine, params, 1);
    if (machine.flags.zero) {
        machine.ip = (cast(int)params[0])-1;
    }
    return 0;
}
int jnz(ref Machine machine, real[] params) {
    handleRegisters(machine, params, 1);
    if (!machine.flags.zero) {
        machine.ip = (cast(int)params[0])-1;
    }
    return 0;}
int read(ref Machine machine, real[] params) {
     handleRegisters(machine, params, 1);
     setRegister(machine, params[1]-real.max, machine.memory[params[0]]);
     return 0;
}
int write(ref Machine machine, real[] params) {
    handleRegisters(machine, params, 3);
    
        machine.memory[params[1]] = params[0];
        return 0;
    
}
int push(ref Machine machine, real[] params) {
    handleRegisters(machine, params, 1);
    machine.stack.length = machine.stack.length + 1;
    machine.stack[machine.stack.length-1] = params[0];
    return 0;
}
int pop(ref Machine machine, real[] params) {

    if(machine.stack.length!=machine.bp){setRegister(machine, params[1]-real.max, machine.stack[machine.stack.length-1]);machine.stack=machine.stack.remove(machine.stack.length-1)}else{
        setRegister(machine, params[1]-real.max, 0);
    }
}
int mov(ref Machine machine, real[] params) {
    cp(machine,params)
    setRegister(machine, params[0]-real.max, 0);
    return 0;
}
int call(ref Machine machine, real[] params) {
    handleRegisters(machine, params, 0);
    for (int j = params.length; j>1; j--) {
         machine.stack.length = machine.stack.length + 1;
    machine.stack[machine.stack.length-1] = params[j]
    }
    machine.p=params.length-1;
    machine.raddr=machine.ip;
    machine.ip = (cast(int)params[0])-1;
    return 0;
}
int ret(ref Machine machine, real[] params) {
    for (int j = params.length; j<machine.p; j++) {
        machine.stack=machine.stack.remove(machine.stack.length-1)
    }
    machine.ip = machine.raddr-1;
    return 0;
}
int nop(ref Machine m,real[]params){return 0;}
