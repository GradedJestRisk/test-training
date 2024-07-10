context('Filesystem', () => {
    context('file', () => {
        it('cy.writeFile() - write to a file', () => {
            const content = "bar";
            const root = "fs-sandbox";
            const fileName = "foo.txt";
            const filePath = root + "/" + fileName;
            cy.writeFile(filePath, content, 'latin1');
        });
    });
});